#include "ADComputeStressTensor.h"
#include "FunctorMaterial.h"
#include "SystemBase.h"
#include <cmath>
#include "MathFVUtils.h"
#include "MooseFunctorArguments.h"
#include "FaceInfo.h"

registerMooseObject("mlApp", ADComputeStressTensor);

InputParameters
ADComputeStressTensor::validParams(){

    InputParameters params = FunctorMaterial::validParams();
    params.addClassDescription("contructs stress from an advected update of the deformation gradient");

    //request velocity
    params.addRequiredParam<MooseFunctorName>("vx", "velocity in x direction");
    params.addRequiredParam<MooseFunctorName>("vy", "velocity in y direction");
    params.addRequiredParam<MooseFunctorName>("vz", "velocity in z direction");

    params.addParam<MooseFunctorName>("velocity_gradient_name", "velocity_gradient", "base name for the velocity gradient row functors (suffixes _row1, _row2, _row3)");

    //request the 9 comopnents of the deformation gradient
    params.addRequiredParam<MooseFunctorName>("F_00", "deformation gradient component 00");
    params.addRequiredParam<MooseFunctorName>("F_01", "deformation gradient component 01");
    params.addRequiredParam<MooseFunctorName>("F_02", "deformation gradient component 02");
    params.addRequiredParam<MooseFunctorName>("F_10", "deformation gradient component 10");
    params.addRequiredParam<MooseFunctorName>("F_11", "deformation gradient component 11");
    params.addRequiredParam<MooseFunctorName>("F_12", "deformation gradient component 12");
    params.addRequiredParam<MooseFunctorName>("F_20", "deformation gradient component 20");
    params.addRequiredParam<MooseFunctorName>("F_21", "deformation gradient component 21");
    params.addRequiredParam<MooseFunctorName>("F_22", "deformation gradient component 22");

    params.addRequiredParam<MooseFunctorName>("lambda_name", "name of the lambda lame constant");
    params.addRequiredParam<MooseFunctorName>("mu_name", "name of the mu lame constant");

    //also provide directly momentum components and density
    params.addRequiredParam<MooseFunctorName>("momentum_vector_name", "name of the momentum vector");
    params.addRequiredParam<MooseFunctorName>("density_name", "name of the density variable");

    ////
    params.addRequiredParam<MooseFunctorName>("stress_col1_name", "name of the stress column 1");
    params.addRequiredParam<MooseFunctorName>("stress_col2_name", "name of the stress column 2");
    params.addRequiredParam<MooseFunctorName>("stress_col3_name", "name of the stress column 3");

    params.addRequiredParam<MooseFunctorName>("T_row1_name", "name of the mechanical flux tensor component in the x direction");
    params.addRequiredParam<MooseFunctorName>("T_row2_name", "name of the mechanical flux tensor component in the y direction");
    params.addRequiredParam<MooseFunctorName>("T_row3_name", "name of the mechanical flux tensor component in the z direction");
    return params;
}

ADComputeStressTensor::ADComputeStressTensor(const InputParameters &params)
    : FunctorMaterial(params),

    //retrieve velocity and gradients
    _vx(getFunctor<ADReal>("vx")),
    _vy(getFunctor<ADReal>("vy")),
    _vz(getFunctor<ADReal>("vz")),
    _velocity_gradient_name(getParam<MooseFunctorName>("velocity_gradient_name")),

    //obtain the 9 components
    //retrieve names
    _F_00(getFunctor<ADReal>("F_00")),
    _F_01(getFunctor<ADReal>("F_01")),
    _F_02(getFunctor<ADReal>("F_02")),
    _F_10(getFunctor<ADReal>("F_10")),
    _F_11(getFunctor<ADReal>("F_11")),
    _F_12(getFunctor<ADReal>("F_12")),
    _F_20(getFunctor<ADReal>("F_20")),
    _F_21(getFunctor<ADReal>("F_21")),
    _F_22(getFunctor<ADReal>("F_22")),

    //rest
    _lambda_name(getParam<MooseFunctorName>("lambda_name")),
    _mu_name(getParam<MooseFunctorName>("mu_name")),
    _momentum_vector_name(getParam<MooseFunctorName>("momentum_vector_name")),
    _density_name(getParam<MooseFunctorName>("density_name")),
    _lambda(getFunctorByName<ADReal>(_lambda_name)),
    _mu(getFunctorByName<ADReal>(_mu_name)),
    _m(getFunctorByName<ADRealVectorValue>(_momentum_vector_name)),
    _rho(getFunctorByName<ADReal>(_density_name))
{

    //define an explicit functor that computes the updated deformation gradient
    auto computeVelocityGradient = [this](const auto & r, const auto & state) -> ADRankTwoTensor{

        //obtain the velocity gradient components
        const ADRealVectorValue gradvx = _vx.gradient(r, state);
        const ADRealVectorValue gradvy = _vy.gradient(r, state);
        const ADRealVectorValue gradvz = _vz.gradient(r, state);

        //assemble the velocity gradient
        ADRankTwoTensor L;
        L(0,0) = gradvx(0); L(0,1) = gradvx(1); L(0,2) = gradvx(2);
        L(1,0) = gradvy(0); L(1,1) = gradvy(1); L(1,2) = gradvy(2);
        L(2,0) = gradvz(0); L(2,1) = gradvz(1); L(2,2) = gradvz(2);

        return L;
    };

    // Expose tensor rows using the vector type supported by functor properties.
    for (unsigned int row = 0; row < 3; ++row)
        addFunctorProperty<ADRealVectorValue>(
            _velocity_gradient_name + "_row" + std::to_string(row + 1),
            [computeVelocityGradient, row](const auto & r, const auto & state) -> ADRealVectorValue{
                const ADRankTwoTensor L = computeVelocityGradient(r, state);
                return ADRealVectorValue(L(row, 0), L(row, 1), L(row, 2));
            });

    //for a lambda that creates stress internally
    auto computeFullStressTensor = [this, computeVelocityGradient](const auto & r, const auto & state) -> ADRankTwoTensor{
        //obtain individual components of the inverse deformation gradient
        const ADReal F_00 = _F_00(r, state);
        const ADReal F_01 = _F_01(r, state);
        const ADReal F_02 = _F_02(r, state);
        const ADReal F_10 = _F_10(r, state);
        const ADReal F_11 = _F_11(r, state);
        const ADReal F_12 = _F_12(r, state);
        const ADReal F_20 = _F_20(r, state);
        const ADReal F_21 = _F_21(r, state);
        const ADReal F_22 = _F_22(r, state);

        //assemble X, being the advected deformation gradient from spatial to current configurations
        ADRankTwoTensor X;
        X(0,0) = F_00; X(0,1) = F_01; X(0,2) = F_02;
        X(1,0) = F_10; X(1,1) = F_11; X(1,2) = F_12;
        X(2,0) = F_20; X(2,1) = F_21; X(2,2) = F_22;

        //form the new deformation gradient from the velocity gradient
        //and a first order approximation

        const ADRankTwoTensor L = computeVelocityGradient(r, state);

        //use the advected deformation gradient as the "old" configuration

        const ADRankTwoTensor F = X + L * X * _dt;

        //use this computed deformation gradient to obtain stress
        ADRankTwoTensor I; I.setToIdentity();

        //obtain constants
        const ADReal lambda = _lambda(r, state);
        const ADReal mu = _mu(r, state);

        //compute right cauchy green deformation tensor
        const ADRankTwoTensor C = F * F.transpose();
        const ADRankTwoTensor E = 0.5 * (C - I);

        //compute stress
        const ADReal traceE = E.trace();

        const ADRankTwoTensor stress = lambda * traceE * I + 2.0 * mu * E;

        return - stress;
    };

    addFunctorProperty<ADRealVectorValue>(getParam<MooseFunctorName>("stress_col1_name"),
        [this, computeFullStressTensor](const auto & r, const auto & state) -> ADRealVectorValue{
            //call the full stress tensor calculation
            const ADRankTwoTensor sigma = computeFullStressTensor(r, state);

            //define the vector
            ADRealVectorValue col1;
            for (unsigned int i = 0; i < 3; ++i){
                col1(i) = sigma(i, 0);
            }
            return col1;
        });

    addFunctorProperty<ADRealVectorValue>(getParam<MooseFunctorName>("stress_col2_name"),
        [this, computeFullStressTensor](const auto & r, const auto & state) -> ADRealVectorValue{
            //call the full stress tensor calculation
            const ADRankTwoTensor sigma = computeFullStressTensor(r, state);

            //define the vector
            ADRealVectorValue col2;
            for (unsigned int i = 0; i < 3; ++i){
                col2(i) = sigma(i, 1);
            }
            return col2;
        });

    addFunctorProperty<ADRealVectorValue>(getParam<MooseFunctorName>("stress_col3_name"),
        [this, computeFullStressTensor](const auto & r, const auto & state) -> ADRealVectorValue{
            //call the full stress tensor calculation
            const ADRankTwoTensor sigma = computeFullStressTensor(r, state);

            //define the vector
            ADRealVectorValue col3;
            for (unsigned int i = 0; i < 3; ++i){
                col3(i) = sigma(i, 2);
            }
            return col3;
        });

    //now compute the full mechanical flux tensor and then expose components

    //first, internally compute a full tensor
    auto computeMechanicalFluxTensor = [this, computeFullStressTensor](const auto & r, const auto & state) -> ADRankTwoTensor{
        //obtain the full stress tensor
        const ADRankTwoTensor sigma = computeFullStressTensor(r, state);

        //obtain the momentum vector
        const ADRealVectorValue m = _m(r, state);
        const ADReal rho = _rho(r, state);

        //compute the tensor

        ADRankTwoTensor T;
        for (unsigned int i = 0; i < 3; ++i){
            for (unsigned int j = 0; j < 3; ++j){
                T(i,j) = m(i) * m(j) / rho;
                T(i,j) -= sigma(i,j);
            }
        }
        return T;
    };

    //now declare the rows using this internal lambda
    addFunctorProperty<ADRealVectorValue>(getParam<MooseFunctorName>("T_row1_name"),
        [this, computeMechanicalFluxTensor](const auto & r, const auto & state) -> ADRealVectorValue{
            // //call the full mechanical flux tensor
            const ADRankTwoTensor T = computeMechanicalFluxTensor(r, state);

            //declare and populate first row
            ADRealVectorValue row1;
            for (unsigned int j = 0; j < 3; ++j){
                row1(j) = T(0,j);
            }
            return row1;
        });

    addFunctorProperty<ADRealVectorValue>(getParam<MooseFunctorName>("T_row2_name"),
        [this, computeMechanicalFluxTensor](const auto & r, const auto & state) -> ADRealVectorValue{
            //call the full mechanical flux tensor
            const ADRankTwoTensor T = computeMechanicalFluxTensor(r, state);

            //declare and populate first row
            ADRealVectorValue row2;
            for (unsigned int j = 0; j < 3; ++j){
                row2(j) = T(1,j);
            }
            return row2;
        });

    addFunctorProperty<ADRealVectorValue>(getParam<MooseFunctorName>("T_row3_name"),
        [this, computeMechanicalFluxTensor](const auto & r, const auto & state) -> ADRealVectorValue{
            //call the full mechanical flux tensor
            const ADRankTwoTensor T = computeMechanicalFluxTensor(r, state);

            //declare and populate first row
            ADRealVectorValue row3;
            for (unsigned int j = 0; j < 3; ++j){
                row3(j) = T(2,j);
            }
            return row3;
        });
}
