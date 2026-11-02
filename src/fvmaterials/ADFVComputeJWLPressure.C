#include "ADFVComputeJWLPressure.h"
#include "FunctorMaterial.h"
#include "SystemBase.h"
#include <cmath>

registerMooseObject("mlApp", ADFVComputeJWLPressure);

InputParameters
ADFVComputeJWLPressure::validParams(){
    //inherit directly the required io stream
    InputParameters params = FunctorMaterial::validParams();

    params.addClassDescription("computes the JWL equation of state from energy");

    params.addParam<MooseFunctorName>("A_name", "A", "name of A parameter for JWL");
    params.addParam<MooseFunctorName>("B_name", "B", "name of B parameter for JWL");
    params.addParam<MooseFunctorName>("R1_name", "R1", "name of R1 parameter for JWL");
    params.addParam<MooseFunctorName>("R2_name", "R2", "name of R2 parameter for JWL");
    params.addParam<MooseFunctorName>("omega_name", "omega", "name of omega parameter for JWL");

    params.addParam<MooseFunctorName>("Jacobian_name", "J", "name of the Jacobian");
    params.addParam<MooseFunctorName>("pressure_name", "pressure", "name of the pressure property");
    params.addParam<MooseFunctorName>("energy_name", "energy", "name of the energy property");
    params.addParam<MooseFunctorName>("density_name", "density", "name of the density property");
    return params;
}

ADFVComputeJWLPressure::ADFVComputeJWLPressure(const InputParameters &params)
    : FunctorMaterial(params),
      _A_name(getParam<MooseFunctorName>("A_name")),
      _A(getFunctor<ADReal>("A_name")),
      _B_name(getParam<MooseFunctorName>("B_name")),
      _B(getFunctor<ADReal>("B_name")),
      _R1_name(getParam<MooseFunctorName>("R1_name")),
      _R1(getFunctor<ADReal>("R1_name")),
      _R2_name(getParam<MooseFunctorName>("R2_name")),
      _R2(getFunctor<ADReal>("R2_name")),
      _omega_name(getParam<MooseFunctorName>("omega_name")),
      _omega(getFunctor<ADReal>("omega_name")),
      _Jacobian_name(getParam<MooseFunctorName>("Jacobian_name")),
      _Jacobian(getFunctor<ADReal>("Jacobian_name")),
      _pressure_name(getParam<MooseFunctorName>("pressure_name")),
      _energy_name(getParam<MooseFunctorName>("energy_name")),
      _energy(getFunctor<ADReal>("energy_name")),
      _density_name(getParam<MooseFunctorName>("density_name")),
      _density(getFunctor<ADReal>("density_name"))
{

    addFunctorProperty<ADReal>(
        _pressure_name,
        [this](const auto & r, const auto & state) -> ADReal{

            //forward declare the required quantities
            const auto A = _A(r, state);
            const auto B = _B(r, state);
            const auto R1 = _R1(r, state);
            const auto R2 = _R2(r, state);
            const auto omega = _omega(r, state);
            const auto J = _Jacobian(r, state);
            const auto energy = _energy(r, state);
            const auto density = _density(r, state);

            //form cold curve
            const ADReal p_cold = A * MetaPhysicL::exp(-R1 * J) + B * MetaPhysicL::exp(-R2 * J);

            //form thermal pressure
            const ADReal p_thermal = omega * energy / density / J;

            //add contributions

            ADReal ptot = p_cold + p_thermal;
            return ptot;
        }
    );
}