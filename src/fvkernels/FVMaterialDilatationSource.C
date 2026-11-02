#include "FVMaterialDilatationSource.h"
#include "MaterialAcousticState.h"
#include "MooseMesh.h"
#include "SubProblem.h"
#include "FaceInfo.h"
#include "MathFVUtils.h"
registerMooseObject("mlApp", FVMaterialDilatationSource);

InputParameters
FVMaterialDilatationSource::validParams()
{
  auto p = FVElementalKernel::validParams();
  p.addRequiredParam<MooseFunctorName>("velocity", "Material velocity in x");
  p.addRequiredParam<MooseFunctorName>("normal_stress", "Normal stress including viscosity");
  p.addRequiredParam<MooseFunctorName>("impedance", "Positive acoustic impedance");
  p.set<unsigned short>("ghost_layers") = 2;
  return p;
}
FVMaterialDilatationSource::FVMaterialDilatationSource(const InputParameters & p)
  : FVElementalKernel(p), _velocity(getFunctor<ADReal>("velocity")),
    _stress(getFunctor<ADReal>("normal_stress")), _impedance(getFunctor<ADReal>("impedance")) {}

ADReal
FVMaterialDilatationSource::computeQpResidual()
{
  const auto state = determineState();
  const auto & mesh = _subproblem.mesh();
  ADReal divergence = 0;
  for (const auto side : _current_elem->side_index_range())
  {
    const Elem * neighbor = _current_elem->neighbor_ptr(side);
    const FaceInfo * fi = (!neighbor || Moose::FV::elemHasFaceInfo(*_current_elem, neighbor))
        ? mesh.faceInfo(_current_elem,side)
        : mesh.faceInfo(neighbor,neighbor->which_neighbor_am_i(_current_elem));
    const auto left = makeElemArg(fi->elemPtr());
    ADReal velocity = _velocity(left,state);
    if (fi->neighborPtr())
    {
      const auto right = makeElemArg(fi->neighborPtr());
      velocity = materialAcousticState(_velocity(left,state),_velocity(right,state),
          _stress(left,state),_stress(right,state),_impedance(left,state),_impedance(right,state),
          fi->normal()(0)).first;
    }
    const Real orientation = fi->elemPtr() == _current_elem ? 1 : -1;
    divergence += orientation*fi->normal()(0)*fi->faceArea()*velocity;
  }
  return -_var(makeElemArg(_current_elem),state)*divergence/_current_elem->volume();
}
