#include "FVEulerianHydroFlux.h"
#include "MooseMesh.h"
#include "MooseException.h"
registerMooseObject("mlApp",FVEulerianHydroFlux);
InputParameters
FVEulerianHydroFlux::validParams()
{
  auto p=FVFluxKernel::validParams();
  p.addClassDescription("Eulerian spherical acoustic/upwind flux, forced bottom inflow and impermeable other walls.");
  for(const auto n:{"rho","mx","my"}) p.addRequiredParam<MooseFunctorName>(n,"Conserved variable");
  p.addParam<MooseFunctorName>("pressure","pressure","Thermodynamic pressure");
  p.addParam<MooseFunctorName>("artificial_pressure","artificial_pressure","Positive viscosity pressure");
  p.addParam<MooseFunctorName>("sound_speed","sound_speed","Signal speed");
  p.addRequiredParam<MooseEnum>("equation",MooseEnum("mass momentum passive"),"Conservation equation");
  p.addRangeCheckedParam<unsigned int>("component",0,"component<2","Momentum component");
  p.addParam<BoundaryName>("inlet_boundary","bottom","Fixed inflow surface, not a moving piston");
  p.addRangeCheckedParam<Real>("inlet_density",1.82,"inlet_density>0","Reservoir density");
  p.addRangeCheckedParam<Real>("inlet_velocity",1.2,"inlet_velocity>=0","Positive y inflow speed");
  p.addParam<MooseFunctorName>("inlet_specific",0,"Inlet Q/rho for a passive conserved variable");
  p.addParam<MooseEnum>("limiter",MooseEnum("upwind minmod","minmod"),"Reconstruction for advected conserved fields");
  p.addParam<MooseEnum>("species_role",MooseEnum("none species1 species2 species3","none"),"Normalize species face masses to their transported total");
  p.addParam<std::vector<MooseFunctorName>>("species",{"rhoY1","rhoY2","rhoY3"},"Species mass densities");
  p.addParam<MooseFunctorName>("species_total","rho_species_total","Transported initial reactive mass density");
  p.set<unsigned short>("ghost_layers")=2;
  p.set<bool>("force_boundary_execution")=true;
  return p;
}
FVEulerianHydroFlux::FVEulerianHydroFlux(const InputParameters & p)
 : FVFluxKernel(p),_rho(getFunctor<ADReal>("rho")),_mx(getFunctor<ADReal>("mx")),_my(getFunctor<ADReal>("my")),
 _pressure(getFunctor<ADReal>("pressure")),_av(getFunctor<ADReal>("artificial_pressure")),
 _sound(getFunctor<ADReal>("sound_speed")),_inlet_specific(getFunctor<ADReal>("inlet_specific")),
 _equation(getParam<MooseEnum>("equation")),_component(getParam<unsigned int>("component")),
 _inlet(_mesh.getBoundaryID(getParam<BoundaryName>("inlet_boundary"))),
 _inlet_density(getParam<Real>("inlet_density")),_inlet_velocity(getParam<Real>("inlet_velocity")),
 _limiter(getParam<MooseEnum>("limiter")=="minmod"?Moose::FV::LimiterType::MinMod:Moose::FV::LimiterType::Upwind),
 _species_role(getParam<MooseEnum>("species_role")),_species_total(nullptr)
{
  if(_species_role!="none") {
    const auto & names=getParam<std::vector<MooseFunctorName>>("species");
    if(names.size()!=3) paramError("species","Exactly three species are required.");
    for(const auto & n:names) _species.push_back(&getFunctorByName<ADReal>(n));
    _species_total=&getFunctor<ADReal>("species_total");
  }
}
ADReal
FVEulerianHydroFlux::computeQpResidual()
{
  const auto s=determineState();const auto l=elemArg();
  const ADReal rl=_rho(l,s);
  if(rl<=0) throw MooseException("Nonpositive Eulerian flux density.");
  const ADRealVectorValue vl(_mx(l,s)/rl,_my(l,s)/rl,0);
  const ADReal pl=_pressure(l,s)+_av(l,s),ul=vl*_normal;
  const ADReal zl=rl*_sound(l,s);
  ADReal mass,pressure;ADRealVectorValue face_velocity;bool left_upwind=true;
  if(onBoundary(*_face_info))
  {
    if(_face_info->boundaryIDs().count(_inlet))
    {
      face_velocity=ADRealVectorValue(0,_inlet_velocity,0);
      const ADReal un=face_velocity*_normal;
      mass=_inlet_density*un;
      pressure=pl+zl*(ul-un);
      if(_equation=="passive")
        return mass*_inlet_specific(singleSidedFaceArg(),s);
    }
    else {mass=0;pressure=pl+zl*ul;face_velocity=vl;}
  }
  else
  {
    const auto r=neighborArg();const ADReal rr=_rho(r,s);
    if(rr<=0) throw MooseException("Nonpositive neighbor mass density.");
    const ADRealVectorValue vr(_mx(r,s)/rr,_my(r,s)/rr,0);
    const ADReal pr=_pressure(r,s)+_av(r,s),ur=vr*_normal,zr=rr*_sound(r,s);
    const ADReal un=(zl*ul+zr*ur+pl-pr)/(zl+zr);
    pressure=(zr*pl+zl*pr+zl*zr*(ul-ur))/(zl+zr);
    left_upwind=un>=0;
    const auto face=makeFace(*_face_info,_limiter,left_upwind);
    const ADReal face_rho=_rho(face,s);
    if(face_rho<=0) throw MooseException("Nonpositive reconstructed face density.");
    face_velocity=ADRealVectorValue(_mx(face,s)/face_rho,_my(face,s)/face_rho,0);
    mass=face_rho*un;
    if(_equation=="passive") {
      ADReal transported=_var(face,s);
      if(_species_role!="none") {
        std::vector<ADReal> species;
        ADReal sum=0;
        for(const auto * field:_species) {
          species.push_back(std::max(ADReal(0),(*field)(face,s)));sum+=species.back();
        }
        const unsigned int i=_species_role=="species1"?0:(_species_role=="species2"?1:2);
        const ADReal total=std::max(ADReal(0),(*_species_total)(face,s));
        transported=sum>0?total*species[i]/sum:(i==0?total:ADReal(0));
      }
      return un*transported;
    }
  }
  if(_equation=="mass") return mass;
  if(_equation=="momentum") return mass*face_velocity(_component)+pressure*_normal(_component);
  return 0; // No passive flux through impermeable walls.
}
