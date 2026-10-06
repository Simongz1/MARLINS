#include "KokkosStressDivergence.h"
#include "MooseMesh.h"
#include "MooseVariableFEBase.h"

registerKokkosResidualObject("mlApp", KokkosStressDivergence);

InputParameters
KokkosStressDivergence::validParams()
{
  auto params = KernelGrad::validParams();
  params.addClassDescription("Cartesian total Lagrangian first Piola stress divergence.");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component < 3", "Displacement component.");
  params.addRequiredCoupledVar("displacements", "Displacements in x, y, z order.");
  params.addParam<MaterialPropertyName>("pk1", "pk1", "First Piola stress.");
  params.addParam<MaterialPropertyName>("dpk1_dF", "dpk1_dF", "Consistent tangent dP_iJ/dF_kL.");
  params.set<bool>("use_displaced_mesh") = false;
  return params;
}

KokkosStressDivergence::KokkosStressDivergence(const InputParameters & parameters)
  : KernelGrad(parameters),
    _component(getParam<unsigned int>("component")),
    _ndisp(coupledComponents("displacements")),
    _pk1(getKokkosMaterialProperty<Real, 2>("pk1")),
    _dpk1_dF(getKokkosMaterialProperty<Real, 4>("dpk1_dF"))
{
  if (_ndisp != _mesh.dimension() || _component >= _ndisp)
    paramError("displacements", "Supply one displacement per mesh dimension and a valid component.");
  if (getParam<bool>("use_displaced_mesh"))
    paramError("use_displaced_mesh", "First Piola stress requires the reference mesh.");
  for (const auto & entry : _mesh.getCoordSystem())
    if (entry.second != Moose::COORD_XYZ)
      mooseError("KokkosStressDivergence requires Cartesian coordinates.");
  for (unsigned int c = 0; c < _ndisp; ++c)
  {
    _disp_var[c] = coupled("displacements", c);
    if (getVar("displacements", c)->feType() != _var.feType())
      paramError("displacements", "All displacements must use the same finite element type.");
    for (unsigned int d = 0; d < c; ++d)
      if (_disp_var[c] == _disp_var[d])
        paramError("displacements", "Displacement variables must be distinct.");
  }
  if (_disp_var[_component] != _var.number())
    paramError("component", "The kernel variable must match displacements[component].");
}
