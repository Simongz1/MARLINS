#include "ADElastoPlastic.h"

registerMooseObject("mlApp", ADElastoPlastic);

InputParameters
ADElastoPlastic::validParams()
{
  InputParameters params = DerivativeMaterialInterface<ADComputeStressBase>::validParams();
  params += ADSingleVariableReturnMappingSolution::validParams();
  params.addClassDescription("Finite strain elasto-plastic response with fracture penalization from phase field model.");
  params.addRequiredParam<MaterialName>("flow_stress_material","The material defining the flow stress");

  //elastic properties
  params.addParam<MaterialPropertyName>("bulk_modulus_name", "bulk_modulus", "name of the bulk modulus");
  params.addParam<MaterialPropertyName>("poisson_ratio_name", "poisson_ratio", "name of the poisson ratio");

  //degradation properties
  params.addParam<MaterialPropertyName>("elastic_degradation_name", "De", "name of the elastic degradation material");
  params.addParam<MaterialPropertyName>("plastic_degradation_name", "Dp", "name of the plastic degradation material");

  //variables
  params.addRequiredCoupledVar("temperature", "temperature");

  //exponential approximation
  params.addParam<bool>("exponential_stretch_approximation", true, "use third order exponential approximation of the stretch increment");
  return params;
}

ADElastoPlastic::ADElastoPlastic(
    const InputParameters & parameters)
  : DerivativeMaterialInterface<ADComputeStressBase>(parameters),
    ADSingleVariableReturnMappingSolution(parameters),
    //retrieve materials and variables
    _T(adCoupledValue("temperature")),
    _bulk_name(getParam<MaterialPropertyName>("bulk_modulus_name")),
    _bulk(getADMaterialPropertyByName<Real>(_bulk_name)),

    _poisson_name(getParam<MaterialPropertyName>("poisson_ratio_name")),
    _poisson(getADMaterialPropertyByName<Real>(_poisson_name)),

    //declare properties
    _F(declareADProperty<RankTwoTensor>("F")),
    _F_old(getMaterialPropertyOld<RankTwoTensor>("F")),

    _Fe(declareADProperty<RankTwoTensor>("Fe")),
    _Fp(declareADProperty<RankTwoTensor>("Fp")),

    _be_bar(declareADProperty<RankTwoTensor>("be_bar")),
    _be_bar_old(getMaterialPropertyOld<RankTwoTensor>("be_bar")),
    _Cp(declareADProperty<RankTwoTensor>("Cp")),
    _Np(declareADProperty<RankTwoTensor>("flow_direction")),
    
    _ep_name("ep"),
    _ep(declareADProperty<Real>("ep")),
    _ep_old(getMaterialPropertyOld<Real>("ep")),
    _ep_dot(declareADProperty<Real>("ep_dot")),
    
    //incremental deformation gradient
    _F_incremental(declareADProperty<RankTwoTensor>("F_incremental")),
    _F_incremental_old(getMaterialPropertyOld<RankTwoTensor>("F_incremental")),
    
    //get computed rotation and stretch increments
    _R_incremental(getADMaterialProperty<RankTwoTensor>("rotation_increment")),
    _U_incremental(getADMaterialProperty<RankTwoTensor>("strain_increment")),

    _flow_stress_material(nullptr),
    _flow_stress_name("flow_stress"),

    //history and strain energy for fracture
    _Hist(declareADProperty<Real>("Hist")),
    _Hist_old(getMaterialPropertyOld<Real>("Hist")),

    //derivatives of yield stress
    _H(getADMaterialPropertyByName<Real>(_flow_stress_name)),
    _dH(getMaterialPropertyDerivativeByName<Real, true>(_flow_stress_name, _ep_name)),
    _d2H(getMaterialPropertyDerivativeByName<Real, true>(_flow_stress_name, _ep_name, _ep_name)),

    _De_name(getParam<MaterialPropertyName>("elastic_degradation_name")),
    _De(getADMaterialPropertyByName<Real>(_De_name)),
    _Dp_name(getParam<MaterialPropertyName>("plastic_degradation_name")),
    _Dp(getADMaterialPropertyByName<Real>(_Dp_name)),

    //declare stresses
    _cauchy(declareADProperty<RankTwoTensor>("cauchy")),
    _pk1(declareADProperty<RankTwoTensor>("pk1")),
    _pk2(declareADProperty<RankTwoTensor>("pk2")),

    //stretch approximation
    _exp_approx(getParam<bool>("exponential_stretch_approximation"))
{
  //nothing here
}

void
ADElastoPlastic::initialSetup()
{
  _flow_stress_material = &getMaterial("flow_stress_material");
}

void
ADElastoPlastic::initQpStatefulProperties()
{
  ADComputeStressBase::initQpStatefulProperties();
  _be_bar[_qp].setToIdentity();
  _ep[_qp] = 0.0;
  _F[_qp].setToIdentity();
  _Hist[_qp] = 0.0;
  _F_incremental[_qp].setToIdentity();
}

void
ADElastoPlastic::computeQpStress()
{
  //compute the shear modulus from bulk and poisson
  const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);

  //incremental update
  const ADRankTwoTensor I = ADRankTwoTensor::Identity();

  //USE APPROXIMATION
  if (_exp_approx){
    ADRankTwoTensor stretch_increment = ADRankTwoTensor::Identity();

    //precompute products
    ADRankTwoTensor U2 = _U_incremental[_qp] * _U_incremental[_qp];
    ADRankTwoTensor U3 = _U_incremental[_qp] * U2;

    stretch_increment += _U_incremental[_qp] + 0.5 * U2 + (1.0 / 6.0) * U3;

    _F_incremental[_qp] = _R_incremental[_qp] * stretch_increment;
  }else{
    _F_incremental[_qp] = _R_incremental[_qp] * (_U_incremental[_qp] + I);
  }
  
  //update total deformation gradient
  _F[_qp] = _F_incremental[_qp] * _F_old[_qp];

  ADReal J_incremental = _F_incremental[_qp].det();
  ADRankTwoTensor f_bar = _F_incremental[_qp] / MetaPhysicL::cbrt(J_incremental);
  ADReal J = _F[_qp].det();

  //rotate strain to current configuration
  _be_bar[_qp] = f_bar * _be_bar_old[_qp] * f_bar.transpose();

  //compute current caucy stress
  ADRankTwoTensor cauchy = _bulk[_qp] * (J - 1.0) * I + (1.0 / J) * shear * _be_bar[_qp].deviatoric();

  //obtain trial kirchhoff
  ADRankTwoTensor kirchhoff = J * cauchy;
  
  //compute the trial deviatoric kirchhoff stress
  ADRankTwoTensor s = kirchhoff.deviatoric();
  ADReal snorm = MetaPhysicL::sqrt(s.doubleContraction(s));

  _Np[_qp] = MooseUtils::absoluteFuzzyEqual(snorm, ADReal(0)) ? std::sqrt(1. / 2.) * I
                                                         : std::sqrt(3. / 2.) * s / snorm;
  ADReal s_eff = s.doubleContraction(_Np[_qp]);

  // Check for plastic loading and do return mapping
  ADReal delta_ep = 0;

  //run radial return 
  if (MetaPhysicL::raw_value(computeResidual(s_eff, 0)) > 0)
  {
    returnMappingSolve(s_eff, delta_ep, _console);
  }

  // Update intermediate and current configurations
  _ep[_qp] = _ep_old[_qp] + delta_ep;
  _ep_dot[_qp] = delta_ep / _dt;
  _be_bar[_qp] -= 2. / 3. * delta_ep * _be_bar[_qp].trace() * _Np[_qp];

  //compute the actual stress here after correction has been applied
  cauchy = _bulk[_qp] * (J - 1.0) * I + (1.0 / J) * shear * _be_bar[_qp].deviatoric();

  //here, we recover the actual be, not the volume preserving part
  ADRankTwoTensor be = MetaPhysicL::pow(J, 2.0 / 3.0) * _be_bar[_qp];
  _Cp[_qp] = _F[_qp].transpose() * be.inverse() * _F[_qp];
  
  //ASSUMING that there is no plastic rotation
  //we approximate the plastic deformation gradient as the sqrt of Cp
  //here we obtain the Ce tensor using a polar decomposition
  //get the symmetric be
  ADRankTwoTensor Cp_sym = 0.5 * (_Cp[_qp] + _Cp[_qp].transpose());

  //get plastic deformation gradient 
  ADRankTwoTensor Q;
  std::vector<ADReal> lam(3);

  //obtain eigenvalues and eigenvectors
  Cp_sym.symmetricEigenvaluesEigenvectors(lam, Q);

  //obtain the diagonal tensor with eigenvalues as principal diagonal
  ADRankTwoTensor sqrt_diag; sqrt_diag.zero();

  //populate the square root of the diagonal tensor
  for (unsigned int i = 0; i < 3; ++i){
    sqrt_diag(i,i) = MetaPhysicL::sqrt(std::max(lam[i], ADReal(1e-12)));
  }

  //reconstruct deformation gradients
  _Fp[_qp] = Q * sqrt_diag * Q.transpose();
  _Fe[_qp] = _F[_qp] * _Fp[_qp].inverse();

  //define a function to perform macaulay brackets
  const auto braket = [](const ADReal & x) -> ADReal
  {
    const Real delta = 1e-6;
    return 0.5 * (x + MetaPhysicL::sqrt(x * x + delta * delta));
  };

  //define braket derivative
  const auto braket_derivative = [](const ADReal & x) -> ADReal
  {
    const Real delta = 1e-6;
    return 0.5 * (1.0 + x / MetaPhysicL::sqrt(x * x + delta * delta));
  };

  //use brakets to obtain region where J-1 > 0 <=> J > 1 <=> expansion
  ADReal Wpos = 0.5 * _bulk[_qp] * MetaPhysicL::pow(braket(J - 1.0), 2) + 0.5 * shear * (_be_bar[_qp].trace() - 3.0);
  ADReal Wneg = 0.5 * _bulk[_qp] * (J - 1.0) * (J - 1.0) + 0.5 * shear * (_be_bar[_qp].trace() - 3.0) - Wpos;

  //update history variable by comparing with the positive energy
  if (Wpos > _Hist_old[_qp]){
    _Hist[_qp] = Wpos;
  }else{
    _Hist[_qp] = _Hist_old[_qp];
  }

  //finally, compute the actual stresses
  //split stress into positive and negative
  ADRankTwoTensor cauchy_pos = _bulk[_qp] * braket(J - 1.0) * braket_derivative(J - 1.0) * I + (1.0 / J) * shear * _be_bar[_qp].deviatoric();
  _cauchy[_qp] = _De[_qp] * (cauchy_pos) + (cauchy - cauchy_pos);
  _pk1[_qp] = J * _cauchy[_qp] * _F[_qp].inverse().transpose();
  _pk2[_qp] = _F[_qp].inverse() * _pk1[_qp];
  _stress[_qp] = _cauchy[_qp];
}

Real
ADElastoPlastic::computeReferenceResidual(const ADReal & effective_trial_stress,
                                                              const ADReal & scalar)
{
  const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
  return MetaPhysicL::raw_value(
      _De[_qp] * effective_trial_stress - _De[_qp] * shear * scalar * _be_bar[_qp].trace());
}

ADReal
ADElastoPlastic::computeResidual(const ADReal & effective_trial_stress,
                                                     const ADReal & scalar)
{
  const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
  // Update the flow stress
  _ep[_qp] = _ep_old[_qp] + scalar;
  _flow_stress_material->computePropertiesAtQp(_qp);
  
  //here we require an exact coupling between Y and the defradation of the yield surface
  //we coupld possibly define degradation functions as in phase field
  return (_De[_qp] * effective_trial_stress - _De[_qp] * shear * scalar * _be_bar[_qp].trace() - _Dp[_qp] * _H[_qp]);
}

ADReal
ADElastoPlastic::computeDerivative(const ADReal & /*effective_trial_stress*/,
                                                       const ADReal & scalar)
{
  const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
  //update the flow stress
  _ep[_qp] = _ep_old[_qp] + scalar;
  _flow_stress_material->computePropertiesAtQp(_qp);

  return (- _De[_qp] * shear * _be_bar[_qp].trace() - _Dp[_qp] * _dH[_qp]);
}
//END