#include "ADPBXStress.h"

registerMooseObject("mlApp", ADPBXStress);

InputParameters
ADPBXStress::validParams()
{
  InputParameters params = DerivativeMaterialInterface<ADComputeStressBase>::validParams();
  params += ADSingleVariableReturnMappingSolution::validParams();
  params.addClassDescription("Object that computes finite strain elasto-plastic response.");
  params.addRequiredParam<MaterialName>("flow_stress_material","The material defining the flow stress");
  params.addRequiredParam<Real>("C0", "artificial viscosity C0 parameter");
  params.addRequiredParam<Real>("C1", "artificial viscosity C1 parameter");
  params.addRequiredParam<Real>("element_size", "element_size");
  params.addCoupledVar("Yinitial", "Yinitial");
  // params.addParam<bool>("euler_angles", true, "euler_angles");
  ///////////////add rule of mixture variables
  params.addRequiredParam<bool>("use_mixture", "use_mixture");
  params.addCoupledVar("fraction_csv", "fraction_csv");

  //parameters for equations of state
  params.addRequiredParam<Real>("A_unreacted", "A_unreacted");
  params.addRequiredParam<Real>("B_unreacted", "B_unreacted");
  params.addRequiredParam<Real>("R1_unreacted", "R1_unreacted");
  params.addRequiredParam<Real>("R2_unreacted", "R2_unreacted");
  params.addRequiredParam<Real>("omega_unreacted", "omega_unreacted");

  params.addRequiredParam<Real>("A_reacted", "A_reacted");
  params.addRequiredParam<Real>("B_reacted", "B_reacted");
  params.addRequiredParam<Real>("R1_reacted", "R1_reacted");
  params.addRequiredParam<Real>("R2_reacted", "R2_reacted");
  params.addRequiredParam<Real>("omega_reacted", "omega_reacted");
  params.addRequiredCoupledVar("temperature", "temperature");

  //here we add a parameter to see whether we use MISTnetX or not
  params.addParam<bool>("use_mistnetx", true, "indicator to use MISTnetX or not");

  //get whether we are using reference or current mesh for cauchy or PK1 stress
  //make this one consistent with the other version
  params.addRequiredParam<std::string>("stress_measure", "specify the stress measure to use for momentum balance");
  params.addParam<std::string>("deformation_gradient_reconstruction", "incremental", "how to reconstruct the deformation gradient");
  params.addRequiredCoupledVar("displacements", "the displacement components");
  
  return params;
}

ADPBXStress::ADPBXStress(
    const InputParameters & parameters)
  : DerivativeMaterialInterface<ADComputeStressBase>(parameters),
    ADSingleVariableReturnMappingSolution(parameters),
    _F(declareADProperty<RankTwoTensor>("deformation_gradient")),
    _F_old(getMaterialPropertyOld<RankTwoTensor>("deformation_gradient")),
    _Fhat(declareADProperty<RankTwoTensor>("Fhat")),

    //obtain bulk and shear for RDX and binder
    _binder_bulk(getADMaterialProperty<Real>("binder_bulk")),
    _binder_poisson(getADMaterialProperty<Real>("binder_poisson")),
    _binder_yield(getADMaterialProperty<Real>("binder_yield")),
    _sigma_binder(declareADProperty<RankTwoTensor>("sigma_binder")),

    _RDX_bulk(getADMaterialProperty<Real>("RDX_bulk")),
    _RDX_poisson(getADMaterialProperty<Real>("RDX_poisson")),
    _sigma_RDX(declareADProperty<RankTwoTensor>("sigma_RDX")),
    _sigma_total(declareADProperty<RankTwoTensor>("sigma_total")),

    //properties for plasticity
    _ep_name("ep"),
    _ep(declareADProperty<Real>(_ep_name)),
    _ep_old(getMaterialPropertyOldByName<Real>(_ep_name)),
    _ep_dot(declareADProperty<Real>("ep_dot")),

    _be_bar(declareADProperty<RankTwoTensor>("be_bar")),
    _be_bar_old(getMaterialPropertyOldByName<RankTwoTensor>("be_bar")),
    _Np(declareADProperty<RankTwoTensor>("flow_direction")),

    //treating Fp as a stateful property
    _Fp(declareADProperty<RankTwoTensor>("Fp")),
    _Fp_old(getMaterialPropertyOld<RankTwoTensor>("Fp")),
    _Fe(declareADProperty<RankTwoTensor>("Fe")),
    _Fe_old(getMaterialPropertyOld<RankTwoTensor>("Fe")),

    //generate strains and rates
    _Ee(declareADProperty<RankTwoTensor>("Ee")),
    _Ee_dot(declareADProperty<RankTwoTensor>("Ee_dot")),

    _Ep(declareADProperty<RankTwoTensor>("Ep")),
    _Ep_dot(declareADProperty<RankTwoTensor>("Ep_dot")),

    _flow_stress_material(nullptr),
    _flow_stress_name("yield_mixture"),
    _H(getADMaterialPropertyByName<Real>(_flow_stress_name)),
    _dH(getMaterialPropertyDerivativeByName<Real>(_flow_stress_name, _ep_name)),
    _d2H(getMaterialPropertyDerivativeByName<Real>(_flow_stress_name, _ep_name, _ep_name)),

    _rho(getADMaterialProperty<Real>("density")),
    _C0(getParam<Real>("C0")),
    _C1(getParam<Real>("C1")),
    _Le(getParam<Real>("element_size")),
    _p_unreacted(declareADProperty<Real>("p_unreacted")),
    _p_reacted(declareADProperty<Real>("p_reacted")),
    _p_av(declareADProperty<Real>("p_av")),
    _p_mix(declareADProperty<Real>("p_mix")),

    //for rule of mixture
    _use_mixture(getParam<bool>("use_mixture")),
    _fraction_csv(coupledValue("fraction_csv")),

    //other properties
    _Cp(declareADProperty<RankTwoTensor>("Cp")),

    _Ep_old(getMaterialPropertyOld<RankTwoTensor>("Ep")),
    _Ee_old(getMaterialPropertyOld<RankTwoTensor>("Ee")),

    _S(declareADProperty<RankTwoTensor>("S")),
    _PK1(declareADProperty<RankTwoTensor>("PK1")),
    _HS_elastic(declareADProperty<Real>("HS_elastic")),
    _HS_plastic(declareADProperty<Real>("HS_plastic")),

    //jacobians
    _Je(declareADProperty<Real>("Je")),
    _Jp(declareADProperty<Real>("Jp")),
    _J(declareADProperty<Real>("J")),

    //green lagrange strains
    _E(declareADProperty<RankTwoTensor>("E")),
    _E_dot(declareADProperty<RankTwoTensor>("E_dot")),

    //increments
    _strain_increment(getADMaterialProperty<RankTwoTensor>("strain_increment")),
    _rotation_increment(getADMaterialProperty<RankTwoTensor>("rotation_increment")),

    _ss(declareADProperty<Real>("ss")),
    _Yinitial(adCoupledValue("Yinitial")),

    ////equation of state parameters
    _A_unreacted(getParam<Real>("A_unreacted")),
    _B_unreacted(getParam<Real>("B_unreacted")),
    _R1_unreacted(getParam<Real>("R1_unreacted")),
    _R2_unreacted(getParam<Real>("R2_unreacted")),
    _omega_unreacted(getParam<Real>("omega_unreacted")),

    _A_reacted(getParam<Real>("A_reacted")),
    _B_reacted(getParam<Real>("B_reacted")),
    _R1_reacted(getParam<Real>("R1_reacted")),
    _R2_reacted(getParam<Real>("R2_reacted")),
    _omega_reacted(getParam<Real>("omega_reacted")),
    _temperature(adCoupledValue("temperature")),
    _cv(getADMaterialProperty<Real>("specific_heat")),

    /////////
    _stress_measure(getParam<std::string>("stress_measure")),
    _reconstruction(getParam<std::string>("deformation_gradient_reconstruction")),
    _ndisp(coupledComponents("displacements")),
    _grad_disp(_ndisp),
    _Y_clamped(),
    _RDX_shear(),
    _binder_shear(),
    _effective_shear(),
    _I(ADRankTwoTensor::Identity())
{
  for (unsigned int i = 0; i < _ndisp; ++i){
    _grad_disp[i] = &adCoupledGradient("displacements", i);
  }
}

void
ADPBXStress::initialSetup()
{
  _flow_stress_material = &getMaterial("flow_stress_material");
}

void
ADPBXStress::initQpStatefulProperties()
{
  ADComputeStressBase::initQpStatefulProperties();
  _be_bar[_qp].setToIdentity();
  _ep[_qp] = 0;
  _Fp[_qp].setToIdentity();
  _Fe[_qp].setToIdentity();
  _Cp[_qp].setToIdentity();
  _F[_qp].setToIdentity();
  _Fhat[_qp].setToIdentity();
}

void
ADPBXStress::computeQpStress()
{
  // Y1 is the remaining unreacted RDX fraction of the whole mixture.
  const Real phi = _use_mixture ? _fraction_csv[_qp] : 1.0;
  _Y_clamped = _Yinitial[_qp] > ADReal(phi) ? ADReal(phi) :
                (_Yinitial[_qp] < ADReal(0.0) ? ADReal(0.0) : _Yinitial[_qp]);

  //compute the shear modulus from bulk and poisson
  _RDX_shear = (3.0 * _RDX_bulk[_qp]) * (1.0 - 2.0 * _RDX_poisson[_qp]) / (2.0 + 2.0 * _RDX_poisson[_qp]);
  _binder_shear = (3.0 * _binder_bulk[_qp]) * (1.0 - 2.0 * _binder_poisson[_qp]) / (2.0 + 2.0 * _binder_poisson[_qp]);

  //general incremental container; it is modified in the next conditionals
  ADRankTwoTensor F_incremental; F_incremental.setToIdentity();

  //reconstruct deformation gradient according to the selected model
  if (_reconstruction == "incremental"){
    //compute exponential of stretch increment
    const ADRankTwoTensor expU = exp(_strain_increment[_qp]);
    F_incremental = _rotation_increment[_qp] * expU;

    //default old incremental branch
    _F[_qp] = F_incremental * _F_old[_qp];

  }else if (_reconstruction == "total"){
    //set the deformation gradient to identity to avoid adding +1
    _F[_qp].setToIdentity();

    //populate from displacements
    for (unsigned int i = 0; i < _ndisp; ++i){
      for (unsigned int j = 0; j < _ndisp; ++j){
        _F[_qp](i, j) += (*_grad_disp[i])[_qp](j);
      }
    }
    //recover incremental
    F_incremental = _F[_qp] * _F_old[_qp].inverse();

  }else{
    paramError("needs incremental or total formulation");
  }

  _Fhat[_qp] = F_incremental;
  ////////////////////////////////////

  //update configuration
  const ADRankTwoTensor f = _Fhat[_qp];
  const ADReal Jhat = f.det();
  const ADRankTwoTensor f_bar = f / MetaPhysicL::cbrt(Jhat);
  const ADReal J = _F[_qp].det();

  //elastic predictor
  _be_bar[_qp] = f_bar * _be_bar_old[_qp] * f_bar.transpose();

  //compute INITIAL mixture properties as function of static fractions
  _mixture_shear = _use_mixture ? 
                   _fraction_csv[_qp] * _RDX_shear + (1 - _fraction_csv[_qp]) * _binder_shear :
                   _RDX_shear;

  _mixture_bulk = _use_mixture ? 
                  _fraction_csv[_qp] * _RDX_bulk[_qp] + (1 - _fraction_csv[_qp]) * _binder_bulk[_qp] : 
                  _RDX_bulk[_qp];
  
  // Use the same phase-weighted shear coefficient for stress and radial return.
  // Reacted RDX carries no deviatoric stress; binder retains its shear response.
  _effective_shear = _Y_clamped * _RDX_shear + (1.0 - phi) * _binder_shear / J;
  const ADRankTwoTensor s_trial = _effective_shear * _be_bar[_qp].deviatoric();

  const ADReal snorm_trial = MetaPhysicL::sqrt(s_trial.doubleContraction(s_trial));
  _Np[_qp] = MooseUtils::absoluteFuzzyEqual(snorm_trial, ADReal(0)) ? std::sqrt(1. / 2.) * _I
                                                         : std::sqrt(3. / 2.) * s_trial / snorm_trial;
  const ADReal s_eff_trial = s_trial.doubleContraction(_Np[_qp]);

  // Check for plastic loading and do return mapping
  ADReal delta_ep = 0;

  //run radial return 
  if (MetaPhysicL::raw_value(computeResidual(s_eff_trial, 0)) > 0)
  {
    returnMappingSolve(s_eff_trial, delta_ep, _console);
  }

  // Update intermediate and current configurations
  _ep[_qp] = _ep_old[_qp] + delta_ep;
  _be_bar[_qp] -= 2. / 3. * delta_ep * _be_bar[_qp].trace() * _Np[_qp];

  // RDX contribution is already weighted by its remaining phase fraction.
  const ADRankTwoTensor s_RDX_corrected =
      _Y_clamped * _RDX_shear * _be_bar[_qp].deviatoric();
  const ADRankTwoTensor s_binder_corrected =
      (_binder_shear / J) * _be_bar[_qp].deviatoric();

  //compute plastic strain rate from radial return increment
  _ep_dot[_qp] = delta_ep / _dt;

  //here, we recover the actual be, not the volume preserving part
  const ADRankTwoTensor be = MetaPhysicL::pow(J, 2.0 / 3.0) * _be_bar[_qp];
  _Cp[_qp] = _F[_qp].transpose() * be.inverse() * _F[_qp];
  
  //ASSUMING that there is no plastic rotation
  //we approximate the plastic deformation gradient as the sqrt of Cp
  //here we obtain the Ce tensor using a polar decomposition
  //get the symmetric be
  const ADRankTwoTensor Cp_sym = 0.5 * (_Cp[_qp] + _Cp[_qp].transpose());

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

  //reconstruct plastic deformation gradient
  _Fp[_qp] = Q * sqrt_diag * Q.transpose();
  //recover elastic deformation gradient
  _Fe[_qp] = _F[_qp] * _Fp[_qp].inverse();

  //compute Lagrangian strains
  _Ee[_qp] = 0.5 * (_Fe[_qp].transpose() * _Fe[_qp] - _I);
  _Ep[_qp] = 0.5 * (_Cp[_qp] - _I);

  const ADRankTwoTensor Fp_dot = (1. / _dt) * (_Fp[_qp] - _Fp_old[_qp]);
  const ADRankTwoTensor Fe_dot = (1. / _dt) * (_Fe[_qp] - _Fe_old[_qp]);
  const ADRankTwoTensor F_dot = (1. / _dt) * (_F[_qp] - _F_old[_qp]);

  _Ep_dot[_qp] = 0.5 * (Fp_dot.transpose() * _Fp[_qp] + _Fp[_qp].transpose() * Fp_dot);
  _Ee_dot[_qp] = 0.5 * (Fe_dot.transpose() * _Fe[_qp] + _Fe[_qp].transpose() * Fe_dot);

  _Je[_qp] = _Fe[_qp].det();
  _Jp[_qp] = _Fp[_qp].det(); //this is only for checking consistency
  _J[_qp] = J;

  //compute pressure for unreacted and reacted material
  _p_unreacted[_qp] = - computeJWLPressure(_A_unreacted, _B_unreacted, _R1_unreacted, _R2_unreacted, _omega_unreacted);
  _p_reacted[_qp] = - computeJWLPressure(_A_reacted, _B_reacted, _R1_reacted, _R2_reacted, _omega_reacted);

  //compute the pressure corresponding only to RDX related response
  _p_mix[_qp] = _Y_clamped * _p_unreacted[_qp] + (phi - _Y_clamped) * _p_reacted[_qp];

  //compute sound speed and bulk modulus from elasticity tensors
  //this is important for the case later on when we add anisotropic behaviour
  const ADReal ss = MetaPhysicL::sqrt((_mixture_bulk + (4.0 / 3.0) * _mixture_shear) * _J[_qp] / _rho[_qp]);
  _ss[_qp] = ss;

  //compute artificial viscosity
  _p_av[_qp] = computeAVPressure();

  //compute the binder stress using a compressible neo-hookean model
  const ADReal binder_vol = _binder_bulk[_qp] * (_J[_qp] - 1.0);
  _sigma_binder[_qp] = binder_vol * _I + s_binder_corrected;

  // Combined RDX contribution (already weighted), including reaction products.
  _sigma_RDX[_qp] = s_RDX_corrected + _p_mix[_qp] * _I;

  _sigma_total[_qp] = _sigma_RDX[_qp] + (1.0 - phi) * _sigma_binder[_qp];

  //use the current configuration to compute the elastic and plastic heat sources
  const ADRankTwoTensor Lp = Fp_dot * _Fp[_qp].inverse();
  const ADRankTwoTensor D = _Fe[_qp] * Lp * _Fe[_qp].inverse();
  const ADRankTwoTensor dp = 0.5 * (D + D.transpose());
  _HS_plastic[_qp] = _sigma_total[_qp].doubleContraction(dp);

  //add here artificial viscosity to cauchy
  _sigma_total[_qp] += _p_av[_qp] * _I;
  _PK1[_qp] = _J[_qp] * _sigma_total[_qp] * _F[_qp].inverse().transpose();
  _S[_qp] = _F[_qp].inverse() * _PK1[_qp];

  //do here stress assignment
  if (_stress_measure == "cauchy"){
    _stress[_qp] = _sigma_total[_qp];
  }else if (_stress_measure == "PK1"){
    _stress[_qp] = _PK1[_qp];
  }else{
    mooseError("the selected stress measure must be cauchy or PK1!");
  }
  
  //compute TOTAL LAGRANGIAN strain and strain rate.
  _E_dot[_qp] = 0.5 * (F_dot.transpose() * _F[_qp] + _F[_qp].transpose() * F_dot);
  _E[_qp] = 0.5 * (_F[_qp].transpose() * _F[_qp] - _I);

  //updated elastic heat source
  const ADReal J_dot = ((_F[_qp].det() - _F_old[_qp].det()) / _dt);
  const ADReal interpolated_omega = _Y_clamped * _omega_unreacted + (phi - _Y_clamped) * _omega_reacted;
  const ADReal dp_dT = interpolated_omega * (_rho[_qp] / _Je[_qp]) * _cv[_qp];
  const ADReal q_eos = - 1.0 * _temperature[_qp] * dp_dT * J_dot / _J[_qp];

  //contract with cauchy stress and save both values
  _HS_elastic[_qp] = q_eos;
  
  //scale heat sources
  if (_stress_measure == "PK1"){
    //the saved expression is in current volume, go back to reference volume
    _HS_plastic[_qp] *= _J[_qp];
    _HS_elastic[_qp] *= _J[_qp];
  }
}

Real
ADPBXStress::computeReferenceResidual(const ADReal & effective_trial_stress,
                                                              const ADReal & scalar)
{

  return MetaPhysicL::raw_value(
      effective_trial_stress - _effective_shear * scalar * _be_bar[_qp].trace());
}

ADReal
ADPBXStress::computeResidual(const ADReal & effective_trial_stress,
                                                     const ADReal & scalar)
{
  // Update the flow stress
  _ep[_qp] = _ep_old[_qp] + scalar;
  _flow_stress_material->computePropertiesAtQp(_qp);
  
  //here we require an exact coupling between Y and the defradation of the yield surface
  //we coupld possibly define degradation functions as in phase field
  return (effective_trial_stress - _effective_shear * scalar * _be_bar[_qp].trace() - _H[_qp]);
}

ADReal
ADPBXStress::computeDerivative(const ADReal & /*effective_trial_stress*/,
                                                       const ADReal & scalar)
{
  //update the flow stress
  _ep[_qp] = _ep_old[_qp] + scalar;
  _flow_stress_material->computePropertiesAtQp(_qp);

  return (- _effective_shear * _be_bar[_qp].trace() - _dH[_qp]);
}

ADReal
ADPBXStress::computeJWLPressure(const Real & A, 
                                      const Real & B,
                                      const Real & R1, 
                                      const Real & R2, 
                                      const Real & omega)
{
  ADReal p = A * MetaPhysicL::exp( - R1 * _Je[_qp] ) + B * MetaPhysicL::exp( - R2 * _Je[_qp]);
  p += omega * _rho[_qp] * _cv[_qp] * (_temperature[_qp] - 300.0) / _Je[_qp];
  p -= A * std::exp(- R1) + B * std::exp(- R2);
  return p;
}

ADReal
ADPBXStress::computeAVPressure()
{ 
  //immediately check for compression
  ADReal J_dot = ((_F[_qp].det() - _F_old[_qp].det()) / _dt);

  if (MetaPhysicL::raw_value(J_dot) >= 0.0){
    //this means expansion, then immediately return 0
    return 0.0;
  }
  
  //else, compute the normal expression 
  else{
    ADReal P_av;
    ADReal J = _F[_qp].det();
    ADReal Le = ADReal(_Le);

    P_av = _C0 * _rho[_qp] * (J_dot * MetaPhysicL::abs(J_dot) / MetaPhysicL::pow(J, 2.0)) * MetaPhysicL::pow(Le, 2.0);
    P_av += _C1 * _rho[_qp] * _ss[_qp] * (J_dot / J) * Le;
    return P_av;
  }
}

//add exponential function
ADRankTwoTensor
ADPBXStress::exp(const ADRankTwoTensor & x){
  
  //eigen decomposition
  ADRankTwoTensor Q;
  std::vector<ADReal> lam(3);
  x.symmetricEigenvaluesEigenvectors(lam, Q);

  //reconstruct exponential
  ADRankTwoTensor expDiag; expDiag.zero();
  for (unsigned int i = 0; i < 3; ++i){
    expDiag(i, i) = MetaPhysicL::exp(lam[i]);
  }

  return Q * expDiag * Q.transpose();
}

//add a function to compute the exact sound speed

//END