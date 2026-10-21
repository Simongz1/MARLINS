#include "ADElastoPlastic.h"
#include <Eigen/LU>

registerMooseObject("mlApp", ADElastoPlastic);

InputParameters
ADElastoPlastic::validParams()
{
  InputParameters params = DerivativeMaterialInterface<ADComputeStressBase>::validParams();
  params += ADSingleVariableReturnMappingSolution::validParams();
  params.addClassDescription("Finite strain elasto-plastic response with fracture penalization from phase field model.");
  params.addRequiredParam<MaterialName>("flow_stress_material", "The material defining the flow stress");
  params.addRequiredParam<MaterialName>("flow_hardening_material", "The material defining the flow hardening function");

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
  params.addParam<bool>("penalize_shear", true, "penalize shear strain energy part");
  params.addParam<std::string>("stress_model", "cauchy", "stress tensor to return");

  //optional artificial viscosity parameters
  params.addParam<bool>("use_artificial_viscosity", false, "use artificial viscosity stabilization for high strain rates");
  params.addParam<Real>("C0", 0.1, "artificial viscosity C0 parameter");
  params.addParam<Real>("C1", 1.0, "artificial viscosity C1 parameter");
  params.addParam<MaterialPropertyName>("h_min_name", "h_min", "name of the material property storing the minimum element size");
  params.addParam<MaterialPropertyName>("density_name", "density", "name of the material property storing the density");

  //request particle model
  params.addParam<std::string>("constitutive_model", "NH", "particle model to follow, can be NH or SVK");
  params.addParam<MaterialPropertyName>("elasticity_tensor_name", "elasticity_tensor", "Name of the externally supplied AD elasticity tensor property (SVK only)");

  //parameters for viscoplastic model for polymer
  params.addParam<bool>("viscoplastic_flow", false, "whether to use viscoplastic flow for NH branch");
  params.addParam<MaterialPropertyName>("viscoplastic_flow_resistance_name", "vp_flow_resistance", "name of the material property storing the viscoplastic flow resistance");
  params.addParam<MaterialPropertyName>("viscoplastic_reference_rate_name", "vp_reference_rate", "name of the material property storing the viscoplastic reference rate");
  params.addParam<MaterialPropertyName>("viscoplastic_rate_exponent_name", "vp_rate_exponent", "name of the material property storing the viscoplastic rate exponent");
  params.addParam<MaterialPropertyName>("viscoplastic_yield_function_name", "vp_f", "name of the material property storing the viscoplastic yield function");
  params.addParam<MaterialPropertyName>("xi_name", "xi", "name of the material property that determines pressure dependence in viscoplastic flow");

  //parameter to enable thermal expansion contribution
  params.addParam<bool>("thermal_expansion", true, "whether to include thermal expansion in the stress calculation");
  params.addParam<MaterialPropertyName>("thermal_expansion_coefficient_name", "thermal_expansion_coefficient", "name of the thermal expansion coefficient");
  params.addParam<bool>("log_model", false, "whether to use the log strain energy in volumetric computation");

  //retrieve newton parameters
  params.addParam<bool>("implicit_plastic_solve", false, "whether to perform a Newton implicit solve for the increment in viscoplastic strain");
  params.addParam<Real>("vp_tol", 1e-8, "residual tolerance for viscoplastic implicit solve");
  params.addParam<int>("vp_maxiter", 30, "maximum number of iterations to perform");
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
    _J(declareADProperty<Real>("J")),
    _Je(declareADProperty<Real>("Je")),
    _J_old(getMaterialPropertyOld<Real>("J")),

    //declare plastic and thermal jacobians
    _Jp(declareADProperty<Real>("Jp")),
    _Jp_old(getMaterialPropertyOld<Real>("Jp")),
    _Jth(declareADProperty<Real>("Jth")),
    _Jth_old(getMaterialPropertyOld<Real>("Jth")),
    _lambda_th(declareADProperty<Real>("lambda_th")),

    _Fe(declareADProperty<RankTwoTensor>("Fe")),
    _Fp(declareADProperty<RankTwoTensor>("Fp")),
    _Fe_old(getMaterialPropertyOld<RankTwoTensor>("Fe")),
    _Fp_old(getMaterialPropertyOld<RankTwoTensor>("Fp")),

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

    //replicate same approach for strain hardening flow function
    _flow_hardening_material(nullptr),

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
    _exp_approx(getParam<bool>("exponential_stretch_approximation")),
    _penalize_shear(getParam<bool>("penalize_shear")),
    _stress_model(getParam<std::string>("stress_model")),

    //for artificial viscosity
    _use_av(getParam<bool>("use_artificial_viscosity")),
    _C0(getParam<Real>("C0")),
    _C1(getParam<Real>("C1")),
    _h_min_name(getParam<MaterialPropertyName>("h_min_name")),
    _h_min(getMaterialPropertyByName<Real>(_h_min_name)),
    _density_name(getParam<MaterialPropertyName>("density_name")),
    _density(getADMaterialPropertyByName<Real>(_density_name)),
    _p_av(_use_av ? &declareADProperty<Real>("p_av") : nullptr),

    //for particle model
    _constitutive_model(getParam<std::string>("constitutive_model")),
    _elasticity_tensor_name(getParam<MaterialPropertyName>("elasticity_tensor_name")),
    _elasticity_tensor(_constitutive_model == "SVK"
                           ? &getADMaterialPropertyByName<RankFourTensor>(_elasticity_tensor_name)
                           : nullptr),

    ///viscoplastic flow model parameters
    _viscoplastic(getParam<bool>("viscoplastic_flow")),
    _vp_flow_resistance_name(getParam<MaterialPropertyName>("viscoplastic_flow_resistance_name")),
    _vp_flow_resistance(_viscoplastic ? &getADMaterialPropertyByName<Real>(_vp_flow_resistance_name) : nullptr),
    _vp_reference_rate_name(getParam<MaterialPropertyName>("viscoplastic_reference_rate_name")),
    _vp_reference_rate(_viscoplastic ? &getADMaterialPropertyByName<Real>(_vp_reference_rate_name) : nullptr),
    _vp_rate_exponent_name(getParam<MaterialPropertyName>("viscoplastic_rate_exponent_name")),
    _vp_rate_exponent(_viscoplastic ? &getADMaterialPropertyByName<Real>(_vp_rate_exponent_name) : nullptr),
    _vp_yield_function_name(getParam<MaterialPropertyName>("viscoplastic_yield_function_name")),
    _vp_yield_function(_viscoplastic ? &getADMaterialPropertyByName<Real>(_vp_yield_function_name) : nullptr),
    
    //retrieve conditional derivatives too
    _vp_yield_function_prime(_viscoplastic ? &getMaterialPropertyDerivativeByName<Real, true>(_vp_yield_function_name, _ep_name) : nullptr),

    _xi_name(getParam<MaterialPropertyName>("xi_name")),
    _xi(_viscoplastic ? &getADMaterialPropertyByName<Real>(_xi_name) : nullptr),

    //thermal expansion parameters
    _thermal_expansion(getParam<bool>("thermal_expansion")),
    _thermal_expansion_coefficient_name(getParam<MaterialPropertyName>("thermal_expansion_coefficient_name")),
    _thermal_expansion_coefficient(_thermal_expansion ? &getADMaterialPropertyByName<Real>(_thermal_expansion_coefficient_name) : nullptr),
    _reference_temperature(declareADProperty<Real>("reference_temperature")),
    _reference_temperature_old(getMaterialPropertyOld<Real>("reference_temperature")),
    _log_model(getParam<bool>("log_model")),

    //parameters for implicit solve
    _implicit(getParam<bool>("implicit_plastic_solve")),
    _vp_tol(_implicit ? &getParam<Real>("vp_tol") : nullptr),
    _vp_maxiter(_implicit ? &getParam<int>("vp_maxiter") : nullptr)

{}

void
ADElastoPlastic::initialSetup()
{
  _flow_stress_material = &getMaterial("flow_stress_material");

  //initialize here
  _flow_hardening_material = &getMaterial("flow_hardening_material");
}

void
ADElastoPlastic::initQpStatefulProperties()
{
  ADComputeStressBase::initQpStatefulProperties();
  _be_bar[_qp].setToIdentity();
  _ep[_qp] = 0.0;
  _F[_qp].setToIdentity();
  _Fe[_qp].setToIdentity();
  _Fp[_qp].setToIdentity();
  _Hist[_qp] = 0.0;
  _F_incremental[_qp].setToIdentity();

  //initialize the elastic jacobian here
  _J[_qp] = 1.0;
  _Je[_qp] = 1.0;
  _Jp[_qp] = 1.0;
  _Jth[_qp] = 1.0;

  //initialize reference temperature
  _reference_temperature[_qp] = _T[_qp];
}

void
ADElastoPlastic::computeQpStress()
{
  //keep reference temperature stateful
  _reference_temperature[_qp] = _reference_temperature_old[_qp];

  //apply thermal expansion here
  if (_thermal_expansion){
    //compute thermal contribution
    _Jth[_qp] = MetaPhysicL::exp(3.0 * (*_thermal_expansion_coefficient)[_qp] * (_T[_qp] - _reference_temperature[_qp]));
  }

  //precompute thermal correction to be used everywhere
  _lambda_th[_qp] = _thermal_expansion ? MetaPhysicL::cbrt(_Jth_old[_qp] / _Jth[_qp]) : 1.0;

  //incremental update
  const ADRankTwoTensor I = ADRankTwoTensor::Identity();

  //USE APPROXIMATION?
  _F_incremental[_qp] = _exp_approx ? 
                        _R_incremental[_qp] * truncExp(_U_incremental[_qp])
                        : _R_incremental[_qp] * (I + _U_incremental[_qp]);

  //update total deformation gradient
  _F[_qp] = _F_incremental[_qp] * _F_old[_qp];
  _J[_qp] = _F[_qp].det();

  //call the viscoplastic update directly here
  if (_viscoplastic){
    if (_constitutive_model != "NH"){
      mooseError("viscoplastic must be matched with NH!");
    }
    viscoPlasticUpdate();
  }
  else{
    const ADReal J_incremental = _F_incremental[_qp].det();
    const ADRankTwoTensor f_bar = _F_incremental[_qp] / MetaPhysicL::cbrt(J_incremental);

    //rotate strain to current configuration
    _be_bar[_qp] = f_bar * _be_bar_old[_qp] * f_bar.transpose();

    /////////////////////////
    // CONSTITUTIVE //
    /////////////////////////

    //form trial state
    ADRankTwoTensor trial_cauchy; trial_cauchy.zero();

    //branch for thermal expansion
    ADRankTwoTensor Fe_trial = _lambda_th[_qp] * _F_incremental[_qp] * _Fe_old[_qp];

    //check whether we are using SVK or NH
    if (_constitutive_model == "NH"){
      trial_cauchy = computeNHCauchyStressTensor(_be_bar[_qp])[0];
    }else if(_constitutive_model == "SVK"){
      trial_cauchy = computeSVKCauchyStressTensor((*_elasticity_tensor)[_qp], Fe_trial)[0];
    }
    else{
      mooseError("Available models are NH or SVK");
    }

    //call flow direction pack
    const std::vector<ADRankTwoTensor> flow_pack = computeFlowDirection(trial_cauchy, Fe_trial);

    //unpack container from flow direction calculation
    //1 -> Flow direction
    //2 -> s stress tensor
    
    _Np[_qp] = flow_pack[0];
    ADRankTwoTensor s = flow_pack[1];
    ADReal s_eff = s.doubleContraction(_Np[_qp]);

    //check for plastic loading and do return mapping
    ADReal delta_ep = 0;

    //run radial return
    if (MetaPhysicL::raw_value(computeResidual(s_eff, 0)) > 0)
    {
      returnMappingSolve(s_eff, delta_ep, _console);
    }

    //update intermediate and current configurations
    _ep[_qp] = _ep_old[_qp] + delta_ep;
    _ep_dot[_qp] = delta_ep / _dt;

    //finalize the actual update with the computed increment
    if (_constitutive_model == "NH"){ //legacy branch
      _be_bar[_qp] -= 2. / 3. * delta_ep * _be_bar[_qp].trace() * _Np[_qp];
      ADRankTwoTensor be = MetaPhysicL::pow(_J[_qp], 2.0 / 3.0) * _be_bar[_qp];
      _Cp[_qp] = _F[_qp].transpose() * be.inverse() * _F[_qp];

      //ASSUMING that there is no plastic rotation
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

      _Fp[_qp] = Q * sqrt_diag * Q.transpose();
      _Fe[_qp] = _F[_qp] * _Fp[_qp].inverse() / MetaPhysicL::cbrt(_Jth[_qp]);
    }
    else if (_constitutive_model == "SVK"){
      //reconstruct updated elastic deformation gradient
      _Fe[_qp] = Fe_trial * truncExp(-delta_ep * _Np[_qp]);
      _Fp[_qp] = _Fe[_qp].inverse() * _F[_qp] / MetaPhysicL::cbrt(_Jth[_qp]);

      //compute needed stuff after
      _Cp[_qp] = _Fp[_qp].transpose() * _Fp[_qp];
    } 
  }

  //assign the elastic jacobian here 
  _Je[_qp] = _Fe[_qp].det();
  _Jp[_qp] = _Fp[_qp].det();

  //compute the actual stress here after correction has been applied
  //here, recomputed using the specific branch

  StressSplit stresses;
  ADRealVectorValue energy;
  if (_constitutive_model == "NH"){
    stresses = computeNHCauchyStressTensor(_be_bar[_qp]);
    energy = computeNHStrainEnergy(_be_bar[_qp]);

  }
  else if (_constitutive_model == "SVK"){
    stresses = computeSVKCauchyStressTensor((*_elasticity_tensor)[_qp], _Fe[_qp]);
    const ADRankTwoTensor Ee = 0.5 * (_Fe[_qp].transpose() * _Fe[_qp] - I);
    energy = computeSVKStrainEnergy((*_elasticity_tensor)[_qp], Ee);
  }
  else{
    mooseError("Unsupported constitutive_model: ", _constitutive_model, ". Expected NH or SVK.");
  }

  const ADReal & Wpos = energy(1);

  //update history variable by comparing with the positive energy
  if (Wpos > _Hist_old[_qp]){
    _Hist[_qp] = Wpos;
  }else{
    _Hist[_qp] = _Hist_old[_qp];
  }

  // Degrade only the positive Cauchy stress from the selected constitutive branch.
  _cauchy[_qp] = _De[_qp] * stresses[1] + stresses[2];
  _pk1[_qp] = _J[_qp] * _cauchy[_qp] * _F[_qp].inverse().transpose();
  _pk2[_qp] = _F[_qp].inverse() * _pk1[_qp];

  //check first what configuraiton we are in
  //artificial viscosity is added at the end

  _stress[_qp] = _stress_model == "cauchy" ? _cauchy[_qp] : _pk1[_qp];

  //check whether we want artificial viscosity
  if (_use_av){
    //obtain artificial viscosity
    const ADReal p_av = computeAVPressure();
    (*_p_av)[_qp] = -p_av;

    //convert artificial viscosity to cauchy or PK1 based on configuration selection
    if (_stress_model == "cauchy"){
      _stress[_qp] -= p_av * I;
    }else{
      //transform to PK1
      _stress[_qp] -= _J[_qp] * p_av * I * _F[_qp].inverse().transpose();
    }
  }
}

//////////////////////////////////////////
////////// PLASTICITY FUNCTIONS //////////
//////////////////////////////////////////

Real
ADElastoPlastic::computeReferenceResidual(const ADReal & effective_trial_stress,
                                                              const ADReal & scalar)
{
  //we preserve the same signature for both cases
  //just change inside depending on the constitutive model passed
  if (_constitutive_model == "NH"){
    const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
    return MetaPhysicL::raw_value(_De[_qp] * effective_trial_stress - _De[_qp] * shear * scalar * _be_bar[_qp].trace());
  }
  
  if (_constitutive_model == "SVK"){
    const ADRankTwoTensor I = ADRankTwoTensor::Identity();
    const ADRankTwoTensor Fe_trial = _lambda_th[_qp] *_F_incremental[_qp] * _Fe_old[_qp];
    const ADRankTwoTensor Ce = Fe_trial.transpose() * Fe_trial;
    const ADRankTwoTensor Ee = 0.5 * (Ce - ADRankTwoTensor::Identity());
    const ADRankTwoTensor Se = (*_elasticity_tensor)[_qp] * Ee;
    const ADRankTwoTensor mandel = Ce * Se;

    // The zero-plastic-spin J2 flow uses the symmetric part of Mandel stress.
    const ADRankTwoTensor mandel_sym = (0.5 * (mandel + mandel.transpose()));
    const ADRankTwoTensor mandel_symdev = mandel_sym.deviatoric();
    // Extract the value before sqrt: this convergence scale does not need AD derivatives.
    const Real q_squared = MetaPhysicL::raw_value(_De[_qp] * 1.5 * mandel_symdev.doubleContraction(mandel_symdev));
    return std::sqrt(q_squared);
  }

  mooseError("Invalid constitutive model. The accepted models are Saint Venant-Kirchhoff (SVK) and Neo-Hookean (NH) !!");
}

ADReal
ADElastoPlastic::computeResidual(const ADReal & effective_trial_stress,
                                 const ADReal & scalar)
{
  if (_constitutive_model == "NH"){
    const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
    // Update the flow stress
    _ep[_qp] = _ep_old[_qp] + scalar;
    _flow_stress_material->computePropertiesAtQp(_qp);

    //here we require an exact coupling between Y and the defradation of the yield surface
    //we coupld possibly define degradation functions as in phase field
    return (_De[_qp] * effective_trial_stress - _De[_qp] * shear * scalar * _be_bar[_qp].trace() - _Dp[_qp] * _H[_qp]);
  }
  
  if (_constitutive_model == "SVK"){
    //compute updated elastic deformation gradient
    const ADRankTwoTensor I = ADRankTwoTensor::Identity();
    const ADRankTwoTensor Fe_trial = _lambda_th[_qp] *_F_incremental[_qp] * _Fe_old[_qp];
    ADRankTwoTensor Fe_update = Fe_trial * truncExp(-scalar * _Np[_qp]);
    ADRankTwoTensor Ce_update = Fe_update.transpose() * Fe_update;
    ADRankTwoTensor Ee_update = 0.5 * (Ce_update - I);
    ADRankTwoTensor Se_update = (*_elasticity_tensor)[_qp] * Ee_update;
    ADRankTwoTensor mandel_update = Ce_update * Se_update;

    //compute q
    ADRankTwoTensor mandel_sym = 0.5 * (mandel_update + mandel_update.transpose());
    ADRankTwoTensor mandel_symdev = mandel_sym.deviatoric();
    ADReal q = std::sqrt(3.0 / 2.0) * MetaPhysicL::sqrt(mandel_symdev.doubleContraction(mandel_symdev));

    //compute yield
    _ep[_qp] = _ep_old[_qp] + scalar;
    _flow_stress_material->computePropertiesAtQp(_qp);

    return _De[_qp] * q - _Dp[_qp] * _H[_qp];
  }

  //if we get here, error out
  mooseError("Invalid constitutive model. The accepted models are Saint Venant-Kirchhoff (SVK) and Neo-Hookean (NH) !!");
}

ADReal
ADElastoPlastic::computeDerivative(const ADReal & /*effective_trial_stress*/,
                                                       const ADReal & scalar)
{
  if (_constitutive_model == "NH"){
    const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
    //update the flow stress
    _ep[_qp] = _ep_old[_qp] + scalar;
    _flow_stress_material->computePropertiesAtQp(_qp);

    return (- _De[_qp] * shear * _be_bar[_qp].trace() - _Dp[_qp] * _dH[_qp]);
  }
  
  if (_constitutive_model == "SVK"){
    //same base stuff
    const ADRankTwoTensor I = ADRankTwoTensor::Identity();
    const ADRankTwoTensor Fe_trial = _lambda_th[_qp] * _F_incremental[_qp] * _Fe_old[_qp];
    ADRankTwoTensor Fe_update = Fe_trial * truncExp(-scalar * _Np[_qp]);
    ADRankTwoTensor Ce_update = Fe_update.transpose() * Fe_update;
    ADRankTwoTensor Ee_update = 0.5 * (Ce_update - I);
    ADRankTwoTensor Se_update = (*_elasticity_tensor)[_qp] * Ee_update;
    ADRankTwoTensor mandel_update = Ce_update * Se_update;

    //compute q
    ADRankTwoTensor mandel_sym = 0.5 * (mandel_update + mandel_update.transpose());
    ADRankTwoTensor mandel_symdev = mandel_sym.deviatoric();
    ADReal q = std::sqrt(3.0 / 2.0) * MetaPhysicL::sqrt(mandel_symdev.doubleContraction(mandel_symdev));

    //compute dFe_dscalar
    ADRankTwoTensor dFe_dscalar = - Fe_trial * _Np[_qp] * truncExpDerivative(-scalar * _Np[_qp]);

    //compute dCe_dscalar = dCe_dF * dFe_dscalar
    ADRankTwoTensor dCe_dscalar = dFe_dscalar.transpose() * Fe_update + Fe_update.transpose() * dFe_dscalar;

    //compute dS_dscalar
    ADRankTwoTensor dSe_dscalar = 0.5 * (*_elasticity_tensor)[_qp] * dCe_dscalar;
    ADRankTwoTensor dM_dscalar = dCe_dscalar * Se_update + Ce_update * dSe_dscalar;

    //obtain stress
    ADRankTwoTensor dM_dscalar_sym = 0.5 * (dM_dscalar + dM_dscalar.transpose());
    ADRankTwoTensor dM_dscalar_symdev = dM_dscalar_sym.deviatoric();

    //compute derivative of q
    ADRankTwoTensor ds_dscalar = dM_dscalar.deviatoric();
    ADReal dq_dscalar = (3.0 / (2.0 * q)) * mandel_symdev.doubleContraction(dM_dscalar_symdev);

    return _De[_qp] * dq_dscalar - _Dp[_qp] * _dH[_qp];
  }

  //if we get here, error out
  mooseError("Invalid constitutive model. The accepted models are Saint Venant-Kirchhoff (SVK) and Neo-Hookean (NH) !!");
}

//helper function for flow direction
std::vector<ADRankTwoTensor>
ADElastoPlastic::computeFlowDirection(const ADRankTwoTensor & cauchy_stress, const ADRankTwoTensor & elastic_deformation_gradient){
  if (_constitutive_model == "NH"){
    const ADRankTwoTensor I = ADRankTwoTensor::Identity();

    //internal branch for viscoplastic
    if (_viscoplastic){
      //compute the flow direction from the local elastic stress
      //the stress already comes from the the previous dependencies
      const ADRankTwoTensor I = ADRankTwoTensor::Identity();
      const ADRankTwoTensor s = cauchy_stress.deviatoric();
      const ADReal q = MetaPhysicL::sqrt((3.0 / 2.0) * s.doubleContraction(s));
      const ADReal t = cauchy_stress.trace();

      //retrieve the actual xi
      const ADReal xi = (*_xi)[_qp];
      const ADRankTwoTensor A = 3.0 * (1.0 - xi) * s + 2.0 * xi * braket(t) * I;
      const ADRankTwoTensor flow_direction = std::sqrt(3.0 / 2.0) * A / MetaPhysicL::sqrt(A.doubleContraction(A));
      return {flow_direction, s};
    }
    
    const ADRankTwoTensor kirchhoff = _J[_qp] * cauchy_stress;
    //compute the trial deviatoric kirchhoff stress: INDEPENDENT
    const ADRankTwoTensor s = kirchhoff.deviatoric();

    const ADReal snorm_squared = s.doubleContraction(s);
    ADRankTwoTensor flow_direction;
    flow_direction.zero();

    if (MetaPhysicL::raw_value(snorm_squared) > 0.0)
    {
      const ADReal snorm = MetaPhysicL::sqrt(snorm_squared);
      flow_direction = std::sqrt(1.5) * s / snorm;
    }

    return {flow_direction, s};
  }
  if (_constitutive_model == "SVK"){
    //use the trial deformation gradient
    const ADRankTwoTensor I = ADRankTwoTensor::Identity();
    const ADRankTwoTensor Fe = elastic_deformation_gradient;
    const ADRankTwoTensor Ce = Fe.transpose() * Fe;
    const ADRankTwoTensor Ee = 0.5 * (Ce - I);
    const ADRankFourTensor Cijkl = (*_elasticity_tensor)[_qp];

    //compute pk2 stress and mandel
    const ADRankTwoTensor Se = Cijkl * Ee;
    const ADRankTwoTensor mandel = Ce * Se;
    const ADRankTwoTensor s = 0.5 * (mandel + mandel.transpose());
    const ADRankTwoTensor sdev = s.deviatoric();

    //compute flow direction
    const ADReal snorm_squared = sdev.doubleContraction(sdev);
    
    ADRankTwoTensor flow_direction; flow_direction.zero();
    
    if (MetaPhysicL::raw_value(snorm_squared) > 0.0){
      const ADReal snorm = MetaPhysicL::sqrt(snorm_squared);
      flow_direction = std::sqrt(1.5) * sdev / snorm;
    }
          
    return {flow_direction, sdev};
  }
  //if we get here, error out
  mooseError("Invalid constitutive model. The accepted models are Saint Venant-Kirchhoff (SVK) and Neo-Hookean (NH) !!");
}

//add an artificial viscosity option
//this will only be used if requested

ADReal
ADElastoPlastic::computeAVPressure()
{
  //immediately check for compression
  ADReal J_dot = (_J[_qp] - _J_old[_qp]) / _dt;

  //compute sound speed
  const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
  ADReal current_density = _density[_qp]; //density is passed as current value
  ADReal sound_speed = MetaPhysicL::sqrt((_bulk[_qp] + (4.0 / 3.0) * shear) / current_density);

  if (MetaPhysicL::raw_value(J_dot) >= 0.0){
    //this means expansion, then immediately return 0
    return 0.0;
  }

  //else, compute the normal expression
  else{
    ADReal P_av;
    P_av = _C0 * _density[_qp] * (J_dot * MetaPhysicL::abs(J_dot) / MetaPhysicL::pow(_J[_qp], 2.0)) * std::pow(_h_min[_qp], 2.0);
    P_av += _C1 * _density[_qp] * sound_speed * (J_dot / _J[_qp]) * _h_min[_qp];
    return - 1.0 * P_av;
  }
}

////////////////////////////////////////////////
/////////////// STRESS FUNCTIONS ///////////////
////////////////////////////////////////////////

ADElastoPlastic::StressSplit
ADElastoPlastic::computeSVKCauchyStressTensor(
    const ADRankFourTensor & elasticity_tensor,
    const ADRankTwoTensor & elastic_deformation_gradient)
{
  const ADRankTwoTensor I = ADRankTwoTensor::Identity();
  const ADRankTwoTensor Ee = 0.5 *
      (elastic_deformation_gradient.transpose() * elastic_deformation_gradient - I);
  const ADReal t = Ee.trace();
  const ADRankTwoTensor A = computeSVKVolumetricCompliance(elasticity_tensor);
  const ADReal kappa = 1.0 / A.trace();

  // Differentiate the smoothed SVK energy split with respect to Ee.
  const ADRankTwoTensor S = elasticity_tensor * Ee;
  ADRankTwoTensor Spos = kappa * braket(t) * braketDerivative(t) * I;
  if (_penalize_shear)
    Spos += S - kappa * t * I;

  // These second Piola stresses are conjugate to elastic Green-Lagrange strain.
  const ADReal Je = elastic_deformation_gradient.det();
  const ADRankTwoTensor total =
      (elastic_deformation_gradient * S * elastic_deformation_gradient.transpose()) / Je;
  const ADRankTwoTensor positive =
      (elastic_deformation_gradient * Spos * elastic_deformation_gradient.transpose()) / Je;
  const ADRankTwoTensor negative = total - positive;
  return {total, positive, negative};
}

ADElastoPlastic::StressSplit
ADElastoPlastic::computeNHCauchyStressTensor(const ADRankTwoTensor & be_bar)
{
  if (!_viscoplastic){
    const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
    const ADRankTwoTensor I = ADRankTwoTensor::Identity();

    //branch based on log model
    if (_log_model){
      //compute pressure
      const ADReal p = 0.5 * _bulk[_qp] * (_J[_qp] * _J[_qp] - 1.0) / _J[_qp];
      const ADRankTwoTensor deviatoric = (shear / _J[_qp]) * be_bar.deviatoric();
      const ADRankTwoTensor total = p * I + deviatoric;

      //compute positive
      ADRankTwoTensor positive = (_J[_qp] - 1.0 > ADReal(0.0)) ? p * I : 0.0 * I;
      
      //add deviatoric part if we are penalizing it
      if (_penalize_shear){
        positive += deviatoric;
      }

      //form negative 
      const ADRankTwoTensor negative = total - positive;
      return {total, positive, negative};
    }else{
      const ADReal volume_change = _J[_qp] - 1.0;
      const ADRankTwoTensor deviatoric = (shear / _J[_qp]) * be_bar.deviatoric();
      const ADRankTwoTensor total = _bulk[_qp] * volume_change * I + deviatoric;
      ADRankTwoTensor positive =
          _bulk[_qp] * braket(volume_change) * braketDerivative(volume_change) * I;
      if (_penalize_shear)
        positive += deviatoric;

      const ADRankTwoTensor negative = total - positive;
      return {total, positive, negative};
    }
  }
  if (_viscoplastic){
    const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
    const ADRankTwoTensor I = ADRankTwoTensor::Identity();

    //here we need to reconstruct elastic tensors
    const ADRankTwoTensor Ce = _Fe[_qp].transpose() * _Fe[_qp];
    const ADReal Je = _Fe[_qp].det();

    //form the new be_bar from the elastic deformation gradient
    const ADRankTwoTensor local_be_bar = MetaPhysicL::pow(Je, - 2.0 / 3.0) * _Fe[_qp] * _Fe[_qp].transpose();
    
    //repeat same approach for this branch
    if (_log_model){
      //compute pressure
      const ADReal p = 0.5 * _bulk[_qp] * (Je * Je - 1.0) / Je;
      const ADRankTwoTensor deviatoric = (shear / Je) * local_be_bar.deviatoric();
      const ADRankTwoTensor total = p * I + deviatoric;

      //compute positive
      ADRankTwoTensor positive = (Je - 1.0 > ADReal(0.0)) ? p * I : 0.0 * I;
      
      //add deviatoric part if we are penalizing it
      if (_penalize_shear){
        positive += deviatoric;
      }

      //form negative 
      const ADRankTwoTensor negative = total - positive;
      return {total, positive, negative};

    }else{
      const ADReal volume_change = Je - 1.0;
      const ADRankTwoTensor deviatoric = (shear / Je) * local_be_bar.deviatoric();
      const ADRankTwoTensor total = _bulk[_qp] * volume_change * I + deviatoric;
      ADRankTwoTensor positive = _bulk[_qp] * braket(volume_change) * braketDerivative(volume_change) * I;
      if (_penalize_shear){
        positive += deviatoric;
      }

      const ADRankTwoTensor negative = total - positive;
      return {total, positive, negative};
    }
  }
  mooseError("Invalid constitutive model. The accepted models are Saint Venant-Kirchhoff (SVK) and Neo-Hookean (NH) !!");
}

///////////////////////////////////////////////////////
/////////////// STRAIN ENERGY FUNCTIONS ///////////////
///////////////////////////////////////////////////////

ADRankTwoTensor
ADElastoPlastic::computeSVKVolumetricCompliance(const ADRankFourTensor & elasticity_tensor)
{
  //compliance matrix
  const unsigned int pair[6][2] = {
    {0, 0}, {1, 1}, {2, 2},
    {1, 2}, {0, 2}, {0, 1}
  };

  Eigen::Matrix<ADReal, 6, 6> M;
  Eigen::Matrix<ADReal, 6, 1> rhs;

  //fill
  for (unsigned int a = 0; a < 6; ++a){
    const unsigned int i = pair[a][0];
    const unsigned int j = pair[a][1];

    rhs(a) = (i == j) ? 1.0 : 0.0;

    for (unsigned int b = 0; b < 6; ++b){
      const unsigned int k = pair[b][0];
      const unsigned int l = pair[b][1];

      //unknowns
      M(a, b) = elasticity_tensor(i, j, k, l);

      if (k != l){
        M(a, b) += elasticity_tensor(i, j, l, k);
      }
    }
  }

  //solve
  const Eigen::Matrix<ADReal, 6, 1> solution = M.partialPivLu().solve(rhs);

  //keep compliance local to the supplied tensor; it can differ between blocks.
  ADRankTwoTensor A;
  A.zero();
  for (unsigned int a = 0; a < 6; ++a){
    const unsigned int i = pair[a][0];
    const unsigned int j = pair[a][1];

    A(i, j) = A(j, i) = solution(a);
  }

  //error out if A has negative trace
  if (A.trace() <= 0.0){
    mooseError("A needs positive trace");
  }

  return A;
}

ADRealVectorValue
ADElastoPlastic::computeSVKStrainEnergy(const ADRankFourTensor & rotated_elasticity_tensor,
                                        const ADRankTwoTensor & lagrangian_strain_tensor)
{
  const ADRankTwoTensor A = computeSVKVolumetricCompliance(rotated_elasticity_tensor);
  const ADReal kappa = 1.0 / A.trace();

  //compute trace and deviatoric parts
  ADReal trE = lagrangian_strain_tensor.trace();

  //call brakets here
  //compute volumetric split
  const ADReal Wvolpos = 0.5 * kappa * braket(trE) * braket(trE);
  const ADReal Wvolneg = 0.5 * kappa * trE * trE - Wvolpos;

  //compute deviatoric part
  const ADRankTwoTensor Er = lagrangian_strain_tensor - kappa * trE * A;

  ADReal Wdev = 0.0;
  for (unsigned int i = 0; i < 3; ++i){
    for (unsigned int j = 0; j < 3; ++j){
      for (unsigned int k = 0; k < 3; ++k){
        for (unsigned int l = 0; l < 3; ++l){
          Wdev += 0.5 * Er(i,j) * rotated_elasticity_tensor(i,j,k,l) * Er(k,l);
        }
      }
    }
  }

  //assemble everything, then return depending on requested split
  const ADReal total = Wvolpos + Wvolneg + Wdev;
  ADReal positive = _penalize_shear ? (Wvolpos + Wdev) : (Wvolpos);
  ADReal negative = total - positive;

  return {total, positive, negative};
}

ADRealVectorValue
ADElastoPlastic::computeNHStrainEnergy(const ADRankTwoTensor & be_bar)
{
  const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);
  ADReal J_energy = _J[_qp];
  ADRankTwoTensor be_bar_energy = be_bar;

  if (_viscoplastic){
    J_energy = _Fe[_qp].det();
    be_bar_energy = MetaPhysicL::pow(J_energy, -2.0 / 3.0) * _Fe[_qp] * _Fe[_qp].transpose();
  }

  //branch on log model
  if (_log_model){
    //compute the volumetric energy
    const ADReal Wvol = 0.25 * _bulk[_qp] * (J_energy * J_energy - 1.0 - 2.0 * MetaPhysicL::log(J_energy));
    const ADReal Wdev = 0.5 * shear * (be_bar_energy.trace() - 3.0);
    const ADReal Wvolpos = J_energy > ADReal(1.0) ? Wvol : ADReal(0.0);

    //assemble total energy
    const ADReal total = Wvol + Wdev;
    const ADReal positive = Wvolpos + (_penalize_shear ? Wdev : ADReal(0.0));
    const ADReal negative = total - positive;

    //return statement
    return {total, positive, negative};
  }
  const ADReal volume_change = J_energy - 1.0;
  const ADReal Wvol = 0.5 * _bulk[_qp] * volume_change * volume_change;
  const ADReal Wdev = 0.5 * shear * (be_bar_energy.trace() - 3.0);
  const ADReal Wvolpos = 0.5 * _bulk[_qp] * braket(volume_change) * braket(volume_change);

  const ADReal total = Wvol + Wdev;
  const ADReal positive = Wvolpos + (_penalize_shear ? Wdev : ADReal(0.0));
  const ADReal negative = total - positive;

  return {total, positive, negative};
}

//generalized braket functions

ADReal
ADElastoPlastic::braket(const ADReal & x){
  const Real delta = 1e-6;
  return 0.5 * (x + MetaPhysicL::sqrt(x * x + delta * delta));
}

ADReal
ADElastoPlastic::braketDerivative(const ADReal & x){
  const Real delta = 1e-6;
  return 0.5 * (1.0 + x / MetaPhysicL::sqrt(x * x + delta * delta));
}

//define a helper function for a truncated exponential
ADRankTwoTensor 
ADElastoPlastic::truncExp(const ADRankTwoTensor & x)
{
  //truncate to order
  const ADRankTwoTensor I = ADRankTwoTensor::Identity();
  ADRankTwoTensor exp; exp.zero();

  const ADRankTwoTensor x2 = x * x;
  const ADRankTwoTensor x3 = x2 * x;

  exp += I + x + 0.5 * x2 + (1.0 / 6.0) * x3;
  return exp;
}

ADRankTwoTensor
ADElastoPlastic::truncExpDerivative(const ADRankTwoTensor & x)
{
  const ADRankTwoTensor I = ADRankTwoTensor::Identity();
  ADRankTwoTensor exp; exp.zero();

  return I + x + 0.5 * x * x;
}

//write a full viscoplastic update function 
void
ADElastoPlastic::viscoPlasticUpdate(){

  //preserve old accumulated plastic strain
  _ep[_qp] = _ep_old[_qp];
  _ep_dot[_qp] = 0.0;
  _flow_hardening_material->computePropertiesAtQp(_qp);

  //derreference all pointers here
  const ADRankTwoTensor I = ADRankTwoTensor::Identity();

  //step 1: compute trial elastic stress from trial elastic deformation gradient
  const ADRankTwoTensor Fe_trial = _lambda_th[_qp] * _F_incremental[_qp] * _Fe_old[_qp];
  _Fe[_qp] = Fe_trial;
  const ADReal Je_trial = Fe_trial.det();
  const ADRankTwoTensor be_bar_trial = MetaPhysicL::pow(Je_trial, -2.0 / 3.0) * Fe_trial * Fe_trial.transpose();
  const auto stress_components = computeNHCauchyStressTensor(be_bar_trial);

  //unpack stress components
  const ADRankTwoTensor sigma_e_trial = _De[_qp] * stress_components[1] + stress_components[2];

  //use the compute trial elastic stress to compute q
  const ADRankTwoTensor sigma_e_trial_deviatoric = sigma_e_trial.deviatoric();

  const ADReal q_squared = 1.5 * sigma_e_trial_deviatoric.doubleContraction(sigma_e_trial_deviatoric);

  if (MetaPhysicL::raw_value(q_squared) <= 0.0)
  {
    _Fp[_qp] = _Fp_old[_qp];
    _Fe[_qp] = Fe_trial;
    _ep[_qp] = _ep_old[_qp];
    _ep_dot[_qp] = 0.0;

    _Np[_qp].zero();
    _Cp[_qp] = _Fp[_qp].transpose() * _Fp[_qp];
    _be_bar[_qp] = be_bar_trial;

    return;
  }
  const ADReal q_trial = MetaPhysicL::sqrt(q_squared);

  //compute A tensor for flow direction
  const ADReal t = sigma_e_trial.trace();
  const ADRankTwoTensor A_trial = 3.0 * (1.0 - (*_xi)[_qp]) * sigma_e_trial_deviatoric + 2.0 * (*_xi)[_qp] * braket(t) * braketDerivative(t) * I;
  
  //compute flow direction
  const ADRankTwoTensor N_trial = std::sqrt(1.5) * A_trial / MetaPhysicL::sqrt(A_trial.doubleContraction(A_trial));

  //se this q value to compute lambda dot

  //before calling vp_yield_function, call qp properties at the supplied material
  _flow_hardening_material->computePropertiesAtQp(_qp);

  //branch here for the implicit update
  ADReal delta_ep = 0.0;
  if (_implicit){
    if(_constitutive_model == "NH"){
      //run implicit solve
      delta_ep = internalPlasticSolve((*_vp_tol),
                                      (*_vp_maxiter),
                                      sigma_e_trial,
                                      Fe_trial);
    }else{
      mooseError("implicit plastic solve is currently only supported with the NeoHookean Branch models.");
    }
  }else{
    const ADReal lambda_dot = (*_vp_reference_rate)[_qp] * MetaPhysicL::pow(q_trial / ((*_vp_flow_resistance)[_qp] * (*_vp_yield_function)[_qp]), (*_vp_rate_exponent)[_qp]);
    //directly compute delta_ep
    delta_ep = _dt * lambda_dot;
  }

  //update the plastic internal variable
  _ep[_qp] = _ep_old[_qp] + delta_ep;
  _ep_dot[_qp] = delta_ep / _dt;

  //update plastic deformation gradient
  //compute incremental plastic deformation gradient
  const ADRankTwoTensor Fp_incremental_inverse = I - _dt * _ep_dot[_qp] * Fe_trial.inverse() * N_trial * Fe_trial;
  _Fp[_qp] = Fp_incremental_inverse.inverse() * _Fp_old[_qp];

  //update the elastic deformation gradient back with the newly computed platic
  _Fe[_qp] = _F[_qp] * _Fp[_qp].inverse() / MetaPhysicL::cbrt(_Jth[_qp]);

  //recompute stress with this elastic deformation gradient
  const ADReal Je_final = _Fe[_qp].det();
  const ADReal Jp_final = _Fp[_qp].det();

  const ADRankTwoTensor be_bar_final = MetaPhysicL::pow(Je_final, -2.0 / 3.0) * _Fe[_qp] * _Fe[_qp].transpose();
  const auto stress_components_final = computeNHCauchyStressTensor(be_bar_final);
  const ADRankTwoTensor sigma_e_final = _De[_qp] * stress_components_final[1] + stress_components_final[2];

  //update the rest of variables
  _be_bar[_qp] = be_bar_final;
  _Cp[_qp] = _Fp[_qp].transpose() * _Fp[_qp];
  _Np[_qp] = N_trial;
}

//define an explicit exponential function

ADRankTwoTensor
ADElastoPlastic::exp(const ADRankTwoTensor & x){
  
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

//define here internal newton solve

ADReal
ADElastoPlastic::internalPlasticSolve(const Real & tol, 
                                      const Real & maxiter,
                                      const ADRankTwoTensor & N_ref,
                                      const ADRankTwoTensor & Fe_ref)
{   

  //evaluate initial residual
  ADReal delta_ep = 0.0;

  const ADRankTwoTensor A = Fe_ref.inverse() * N_ref * Fe_ref;

  for (unsigned int iter = 0; iter < maxiter; iter++){
    //iterate until convergence or maxiter, exit on earliest case
    ADReal current_residual = viscoplasticResidual(delta_ep, Fe_ref, A);
    
    if (std::abs(MetaPhysicL::raw_value(current_residual)) <= tol){
      return delta_ep;
    }

    ADReal current_derivative = viscoplasticDerivative(delta_ep, Fe_ref, A);
    delta_ep -= current_residual / current_derivative;
  }

  mooseError("the iterative plastic solve diverged at ", (*_vp_maxiter), "iterations.\n");
}

//we need helper functions for the residual and derivative
ADReal
ADElastoPlastic::viscoplasticResidual(const ADReal & delta_ep,
                                      const ADRankTwoTensor & Fe_trial,
                                      const ADRankTwoTensor & A)
{   
    const ADRankTwoTensor I = ADRankTwoTensor::Identity();

    //reconstruct state
    _Fe[_qp] = Fe_trial * (I - delta_ep * A);
    _ep[_qp] = _ep_old[_qp] + delta_ep;

    //compute new properties at qp with updated ep
    _flow_hardening_material->computePropertiesAtQp(_qp);

    //compute constants
    const ADReal Je = _Fe[_qp].det();

    const ADReal rate_0 = (*_vp_reference_rate)[_qp];
    const ADReal m = (*_vp_rate_exponent)[_qp];

    const ADRankTwoTensor be_bar = MetaPhysicL::pow(Je, -2.0 / 3.0) * _Fe[_qp] * _Fe[_qp].transpose();
    
    const auto sigma_trial_state = _constitutive_model == "NH" ? computeNHCauchyStressTensor(be_bar) : computeSVKCauchyStressTensor((*_elasticity_tensor)[_qp], _Fe[_qp]);

    //unpack; form the actual stress penalization
    const ADRankTwoTensor sigma = _De[_qp] * sigma_trial_state[1] + sigma_trial_state[2];
    const ADRankTwoTensor s = sigma.deviatoric();
    
    //form residual; compute the effective stress from the penalized trial stress
    const ADReal q = 1.5 * s.doubleContraction(s);
    const ADReal H = (*_vp_flow_resistance)[_qp] * (*_vp_yield_function)[_qp];

    return delta_ep - _dt * rate_0 * MetaPhysicL::pow(q, 0.5 * m) / MetaPhysicL::pow(H, m);
}

//derivative
ADReal
ADElastoPlastic::viscoplasticDerivative(const ADReal & delta_ep,
                                        const ADRankTwoTensor & Fe_trial,
                                        const ADRankTwoTensor & A)
{
  const ADReal shear = (3.0 * _bulk[_qp]) * (1.0 - 2.0 * _poisson[_qp]) / (2.0 + 2.0 * _poisson[_qp]);

  const ADRankTwoTensor I = ADRankTwoTensor::Identity();

  //reconstruct state
  _Fe[_qp] = Fe_trial * (I - delta_ep * A);
  _ep[_qp] = _ep_old[_qp] + delta_ep;

  //compute new properties at qp with updated ep
  _flow_hardening_material->computePropertiesAtQp(_qp);

  //store values
  const ADReal rate_0 = (*_vp_reference_rate)[_qp];
  const ADReal m = (*_vp_rate_exponent)[_qp];
  const ADReal Je = _Fe[_qp].det();

  const ADRankTwoTensor be_bar = MetaPhysicL::pow(Je, -2.0 / 3.0) * _Fe[_qp] * _Fe[_qp].transpose();
  const ADRankTwoTensor be = _Fe[_qp] * _Fe[_qp].transpose();

  //compute stress
  const auto sigma_trial_state = _constitutive_model == "NH" ? computeNHCauchyStressTensor(be_bar) : computeSVKCauchyStressTensor((*_elasticity_tensor)[_qp], _Fe[_qp]);

  const ADRankTwoTensor sigma = _De[_qp] * sigma_trial_state[1] + sigma_trial_state[2];
  const ADRankTwoTensor s = sigma.deviatoric();
  
  //form residual; compute the effective stress from the penalized trial stress
  const ADReal q = 1.5 * s.doubleContraction(s);
  const ADReal H = (*_vp_flow_resistance)[_qp] * (*_vp_yield_function)[_qp];

  //form derivatives of
  const ADRankTwoTensor Fe_prime = - Fe_trial * A;
  const ADReal Je_prime = Je * (_Fe[_qp].inverse() * Fe_prime).trace();

  //compute derivative of be w.r.t delta_p
  const ADRankTwoTensor be_prime = Fe_prime * _Fe[_qp].transpose() + _Fe[_qp] * Fe_prime.transpose();
  const ADRankTwoTensor be_bar_prime = MetaPhysicL::pow(Je, -2.0 / 3.0) * (be_prime - (2.0 / 3.0) * (Je_prime / Je) * be);

  const ADRankTwoTensor s_prime = (_penalize_shear ? _De[_qp] : 1.0) * shear / Je * (be_bar_prime.deviatoric() - (1.0 / Je) * Je_prime * be_bar.deviatoric());
  
  //form Qprime and Hprime
  const ADReal q_prime = 3.0 * s.doubleContraction(s_prime);
  const ADReal H_prime = (*_vp_flow_resistance)[_qp] * (*_vp_yield_function_prime)[_qp];

  const ADReal derivative = 1.0 - _dt * rate_0 * (0.5 * m * MetaPhysicL::pow(q, 0.5 * m - 1.0) * MetaPhysicL::pow(H, -m) * q_prime - m * MetaPhysicL::pow(q, 0.5 * m) * MetaPhysicL::pow(H, - m - 1.0) * H_prime);
  return derivative;
}
//END