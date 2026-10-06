#include "KokkosNeoHookean.h"
#include "MooseMesh.h"

registerKokkosMaterial("mlApp", KokkosNeoHookean);

InputParameters
KokkosNeoHookean::validParams()
{
  auto params = Material::validParams();
  params.addClassDescription("Compressible neo-Hookean energy, first Piola stress and consistent tangent.");
  params.addRequiredCoupledVar("displacements", "Displacements in x, y, z order; 2D is plane strain.");
  params.addRequiredRangeCheckedParam<Real>("bulk_modulus", "bulk_modulus > 0", "Bulk modulus.");
  params.addRequiredRangeCheckedParam<Real>("shear_modulus", "shear_modulus > 0", "Shear modulus.");
  params.addParam<MaterialPropertyName>("strain_energy_density", "strain_energy_density", "Energy per reference volume.");
  params.addParam<MaterialPropertyName>("pk1", "pk1", "First Piola stress.");
  params.addParam<MaterialPropertyName>("dpk1_dF", "dpk1_dF", "Consistent tangent dP_iJ/dF_kL.");
  params.addParam<MaterialPropertyName>("sigma", "sigma", "Cauchy stress.");
  params.set<bool>("use_displaced_mesh") = false;
  return params;
}

KokkosNeoHookean::KokkosNeoHookean(const InputParameters & parameters)
  : Material(parameters),
    _ndisp(coupledComponents("displacements")),
    _grad_disp(kokkosCoupledGradients("displacements")),
    _bulk(getParam<Real>("bulk_modulus")),
    _shear(getParam<Real>("shear_modulus")),
    _energy(declareKokkosProperty<Real>("strain_energy_density")),
    _pk1(declareKokkosProperty<Real, 2>("pk1", {3,3})),
    _dpk1_dF(declareKokkosProperty<Real, 4>("dpk1_dF", {3,3,3,3})),

    //declare cauchy stress for visualization only
    _sigma(declareKokkosProperty<Real, 2>("sigma", {3, 3}))
{
  if (_ndisp != _mesh.dimension() || _ndisp > 3)
    paramError("displacements", "Supply one displacement per mesh dimension.");
  if (getParam<bool>("use_displaced_mesh"))
    paramError("use_displaced_mesh", "The deformation gradient requires the reference mesh.");
  for (const auto & entry : _mesh.getCoordSystem())
    if (entry.second != Moose::COORD_XYZ)
      mooseError("KokkosNeoHookean requires Cartesian coordinates.");
  for (unsigned int c = 0; c < _ndisp; ++c)
    for (unsigned int d = 0; d < c; ++d)
      if (coupled("displacements", c) == coupled("displacements", d))
        paramError("displacements", "Displacement variables must be distinct.");
}