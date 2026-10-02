#!/usr/bin/env python3
"""Generate three constitutive comparisons from a large_comp.i-style NH template.

The template must contain one FileMeshGenerator and one ADElastoPlastic material.
Particle-restricted materials use `block = particles`; polymer materials use
`block = matrix` (both names are configurable). Other input settings are retained.
Only Python's standard library is needed. Named ASCII Gmsh 2.x/4.x meshes work.
"""
import argparse
import math
import os
from pathlib import Path
import random
import re

# Supplied alpha-polymorph table at 295 K, 0 GPa, converted from GPa to MPa.
# MOOSE symmetric9 order: C11 C12 C13 C22 C23 C33 C44 C55 C66.
ALPHA_STIFFNESS = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
# Leaf sections suffice for FileMeshGenerator and ADElastoPlastic in this template.
LEAF = re.compile(r'(?m)^(?P<indent>[ \t]*)\[(?P<name>[^\]\n]+)\][ \t]*\n'
                  r'(?P<body>(?:(?!^[ \t]*\[).*(?:\n|$))*)'
                  r'^[ \t]*\[(?:\.\./)?\][ \t]*$', re.MULTILINE)


def physical_names(mesh):
    with mesh.open() as stream:
        for line in stream:
            if line.strip() == '$MeshFormat':
                version, binary, _ = next(stream).split()
                if binary != '0':
                    raise ValueError('Use an ASCII Gmsh mesh.')
            if line.strip() == '$PhysicalNames':
                result = []
                for _ in range(int(next(stream))):
                    match = re.fullmatch(r'\s*(\d+)\s+(\d+)\s+"([^"]+)"\s*', next(stream))
                    if not match:
                        raise ValueError('Malformed Gmsh physical name.')
                    result.append((int(match[1]), int(match[2]), match[3]))
                return result
    raise ValueError('Mesh has no PhysicalNames section.')


def typed_leaf(text, object_type):
    matches = [m for m in LEAF.finditer(text)
               if re.search(r'^\s*type\s*=\s*' + re.escape(object_type) + r'\s*$',
                            m['body'], re.MULTILINE)]
    if len(matches) != 1:
        raise ValueError('Template must contain exactly one ' + object_type + ' section.')
    return matches[0]


def set_parameter(body, name, value):
    pattern = r'(?m)^[ \t]*' + re.escape(name) + r'[ \t]*=.*$'
    body = re.sub(pattern, '', body)
    return body.rstrip() + '\n        ' + name + ' = ' + value + '\n'


def generate(template, mesh_reference, particles, polymer, particle_group,
             template_polymer, case, angles):
    mesh = typed_leaf(template, 'FileMeshGenerator')
    body = set_parameter(mesh['body'], 'file', "'" + mesh_reference + "'")
    text = template[:mesh.start()] + mesh['indent'] + '[' + mesh['name'] + ']\n' + body + '    []' + template[mesh.end():]
    # Expand aggregate particle assignments without changing other properties.
    for old, new in [(particle_group, ' '.join(particles)), (template_polymer, polymer)]:
        pattern = r"(?m)^([ \t]*block[ \t]*=[ \t]*)['\"]?" + re.escape(old) + r"['\"]?[ \t]*(?:#.*)?$"
        text, count = re.subn(pattern, lambda m: m[1] + "'" + new + "'", text)
        if not count:
            raise ValueError('No template block assignment found for ' + old)

    stress = typed_leaf(text, 'ADElastoPlastic')
    sections = []
    for name, blocks, model in [('particles', ' '.join(particles), 'NH' if case == 'nh' else 'SVK'),
                                ('polymer', polymer, 'NH')]:
        body = set_parameter(stress['body'], 'block', "'" + blocks + "'")
        body = set_parameter(body, 'constitutive_model', model)
        if model == 'SVK':
            body = set_parameter(body, 'elasticity_tensor_name', 'elasticity_tensor')
        sections.append('    [elasto_plastic_' + name + ']\n' + body + '    []\n')

    if case != 'nh':
        sections.append('    # Alpha polymorph stiffness in MPa; material axis 1 is the c-axis.\n'
                        '    # symmetric9: C11 C12 C13 C22 C23 C33 C44 C55 C66.\n'
                        '    # Euler angles: MOOSE Z-X-Z convention, degrees.\n')
        for particle in particles:
            section = ('    [elasticity_' + particle + ']\n'
                       '        type = ADComputeElasticityTensor\n'
                       '        block = ' + particle + '\n'
                       '        fill_method = symmetric9\n'
                       "        C_ijkl = '" + ALPHA_STIFFNESS + "'\n")
            if case == 'svk_rotated':
                for i, angle in enumerate(angles[particle], 1):
                    section += '        euler_angle_{} = {:.10f}\n'.format(i, angle)
            # Omitted angles default to zero in ADComputeElasticityTensor.
            sections.append(section + '    []\n')
    return text[:stress.start()] + ''.join(sections) + text[stress.end():]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--template', required=True, type=Path, help='Original NH input, e.g. large_comp.i')
    parser.add_argument('--mesh', required=True, type=Path)
    parser.add_argument('--output-dir', type=Path, default=Path('.'))
    parser.add_argument('--prefix', default='large')
    parser.add_argument('--particle-prefix', default='particle_')
    parser.add_argument('--polymer-block', default='matrix', help='Polymer physical name in mesh')
    parser.add_argument('--template-particle-block', default='particles')
    parser.add_argument('--template-polymer-block', default='matrix')
    parser.add_argument('--seed', type=int, default=20260929)
    parser.add_argument('--force', action='store_true', help='Overwrite generated input files')
    args = parser.parse_args()
    try:
        names = physical_names(args.mesh)
        dim = max(d for d, _, _ in names)
        blocks = [name for d, _, name in names if d == dim]
        particles = [name for name in blocks if name.startswith(args.particle_prefix)]
        if not particles or args.polymer_block not in blocks:
            raise ValueError('Mesh must contain named particles and the polymer block.')
        if set(blocks) != set(particles) | {args.polymer_block}:
            raise ValueError('Mesh contains additional volume blocks without material assignments.')
        template = args.template.read_text()
        rng = random.Random(args.seed)
        # Uniform orientations on SO(3), not uniform in the middle Euler angle.
        angles = {p: (rng.uniform(0, 360), math.degrees(math.acos(rng.uniform(-1, 1))),
                      rng.uniform(0, 360)) for p in particles}
        reference = os.path.relpath(args.mesh.resolve(), args.output_dir.resolve())
        outputs = {}
        for case in ['nh', 'svk_unrotated', 'svk_rotated']:
            path = args.output_dir / (args.prefix + '_' + case + '.i')
            if path.resolve() == args.template.resolve():
                raise ValueError('Output would overwrite the source template.')
            if path.exists() and not args.force:
                raise ValueError(str(path) + ' exists; use --force to overwrite.')
            header = '# Generated case: {}; polymer NH; {} particles.\n'.format(case, len(particles))
            if case == 'svk_rotated':
                header += '# Uniform random 3D orientations; seed {}.\n'.format(args.seed)
            outputs[path] = header + generate(template, reference, particles, args.polymer_block,
                                             args.template_particle_block, args.template_polymer_block,
                                             case, angles)
        args.output_dir.mkdir(parents=True, exist_ok=True)
        for path, content in outputs.items():
            path.write_text(content)
            print(path)
    except (OSError, ValueError, StopIteration) as exc:
        parser.error(str(exc))


if __name__ == '__main__':
    main()
