#include "FVMaterialUpwindFlux.h"
#include "MaterialAcousticState.h"
registerMooseObject("mlApp", FVMaterialUpwindFlux);

InputParameters
FVMaterialUpwindFlux::validParams()
{
  auto params = FVFluxKernel::validParams();
  params.addRequiredParam<MooseFunctorName>("velocity", "Longitudinal material velocity");
  params.addRequiredParam<MooseFunctorName>("normal_stress", "Cauchy normal stress including artificial viscosity");
  params.addRequiredParam<MooseFunctorName>("impedance", "Positive acoustic impedance rho*c");
  params.addParam<MooseFunctorName>("heat_flux", "0", "Conductive heat flux in x");
  params.addParam<MooseEnum>("equation", MooseEnum("transport momentum energy", "transport"),
                            "Select traction or stress-work contribution");
  params.addParam<MooseEnum>("material_component",
      MooseEnum("none solid species1 species2 species3", "none"),
      "Use a shared density flux and bounded normalized phase/species composition");
  params.addParam<MooseFunctorName>("density", "Total mass density for consistent partial-mass fluxes");
  params.addParam<MooseFunctorName>("solid_density", "Solid partial mass density");
  params.addParam<std::vector<MooseFunctorName>>("species", {}, "Three solid species partial densities");
  params.addParam<MooseEnum>("reconstruction", MooseEnum("upwind minmod vanleer", "minmod"),
                            "Face reconstruction of the transported conserved field");
  // Both the limiter and neighbor-cell conductive/viscous flux need a second layer.
  params.set<unsigned short>("ghost_layers") = 2;
  params.set<bool>("force_boundary_execution") = true;
  return params;
}

FVMaterialUpwindFlux::FVMaterialUpwindFlux(const InputParameters & p)
  : FVFluxKernel(p), _velocity(getFunctor<ADReal>("velocity")),
    _stress(getFunctor<ADReal>("normal_stress")),
    _impedance(getFunctor<ADReal>("impedance")), _heat(getFunctor<ADReal>("heat_flux")),
    _equation(getParam<MooseEnum>("equation")),
    _component(getParam<MooseEnum>("material_component")),
    _density(_component == "none" ? nullptr : &getFunctor<ADReal>("density")),
    _solid(_component == "none" ? nullptr : &getFunctor<ADReal>("solid_density")),
    _limiter(getParam<MooseEnum>("reconstruction") == "upwind" ? Moose::FV::LimiterType::Upwind :
             getParam<MooseEnum>("reconstruction") == "minmod" ? Moose::FV::LimiterType::MinMod :
                                                               Moose::FV::LimiterType::VanLeer)
{
  if (_component != "none")
  {
    const auto & names = getParam<std::vector<MooseFunctorName>>("species");
    if (names.size() != 3)
      paramError("species", "Consistent composition transport requires three species densities");
    for (const auto & name : names)
      _species.push_back(&getFunctorByName<ADReal>(name));
  }
}

ADReal
FVMaterialUpwindFlux::computeQpResidual()
{
  const auto state = determineState();
  const auto left = elemArg();
  ADReal velocity = _velocity(left,state), traction = _stress(left,state);
  ADReal heat = _heat(left,state);
  ADReal transported = _var(left,state);
  if (!onBoundary(*_face_info))
  {
    const auto right = neighborArg();
    const ADReal zl = _impedance(left,state), zr = _impedance(right,state);
    // The common acoustic state is exact for a stationary equal-traction contact.
    // Project velocities into x; the outward face normal is applied only at return.
    const Real nx = _normal(0);
    const auto acoustic = materialAcousticState(_velocity(left,state),_velocity(right,state),
        _stress(left,state),_stress(right,state),zl,zr,nx);
    velocity = acoustic.first;
    traction = acoustic.second;
    heat = 0.5*(_heat(left,state)+_heat(right,state));
    const auto face = makeFace(*_face_info, _limiter,
                               MetaPhysicL::raw_value(velocity)*nx >= 0);
    transported = _var(face,state);
    if (_component != "none")
    {
      const ADReal density = (*_density)(face,state);
      const ADReal solid = std::max(ADReal(0), std::min(density, (*_solid)(face,state)));
      if (_component == "solid")
        transported = solid;
      else
      {
        ADReal sum = 0;
        std::vector<ADReal> species;
        for (const auto * field : _species)
        {
          species.push_back(std::max(ADReal(0), (*field)(face,state)));
          sum += species.back();
        }
        const unsigned int i = _component == "species1" ? 0 : _component == "species2" ? 1 : 2;
        // At a pure-gas face both solid mass and the species sum are zero.
        transported = MetaPhysicL::raw_value(sum) > 0 ? solid*species[i]/sum :
                                                       (i == 0 ? solid : ADReal(0));
      }
    }
  }
  ADReal flux = velocity*transported;
  if (_equation == "momentum")
    flux -= traction;
  else if (_equation == "energy")
    flux += heat-traction*velocity;
  return _normal(0)*flux;
}
