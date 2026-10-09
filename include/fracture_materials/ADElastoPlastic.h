#pragma once

#include <array>

#include "ADComputeStressBase.h"
#include "ElasticityTensorTools.h"
#include "ADSingleVariableReturnMappingSolution.h"
#include "Function.h"
#include "DerivativeMaterialInterface.h"


class ADElastoPlastic
  : public DerivativeMaterialInterface<ADComputeStressBase>,
    public ADSingleVariableReturnMappingSolution
{
public:
  static InputParameters validParams();
  ADElastoPlastic(const InputParameters & parameters);
  virtual void initialSetup() override;

protected:
  virtual void initQpStatefulProperties() override;
  virtual void computeQpStress() override;

  //NH plastic update functions
  virtual Real computeReferenceResidual(const ADReal & effective_trial_stress,
                                        const ADReal & scalar) override;
  virtual ADReal computeResidual(const ADReal & effective_trial_stress, const ADReal & scalar) override;
  virtual ADReal computeDerivative(const ADReal & effective_trial_stress, const ADReal & scalar) override;
  virtual std::vector<ADRankTwoTensor> computeFlowDirection(const ADRankTwoTensor & cauchy_stress,
                                               const ADRankTwoTensor & elastic_deformation_gradient);
  //SVK plastic update functions

  virtual ADReal computeAVPressure();

  /// Cauchy stress components in the order {total, positive, negative}.
  using StressSplit = std::array<ADRankTwoTensor, 3>;
  virtual StressSplit computeSVKCauchyStressTensor(
      const ADRankFourTensor & elasticity_tensor,
      const ADRankTwoTensor & elastic_deformation_gradient);
  virtual StressSplit computeNHCauchyStressTensor(const ADRankTwoTensor & be_bar);

  /// Solve C:A = I for the compliance used by both SVK energy and stress splits.
  ADRankTwoTensor computeSVKVolumetricCompliance(const ADRankFourTensor & elasticity_tensor);

  // Strain energy functions return {total, positive, negative}.
  virtual ADRealVectorValue computeSVKStrainEnergy(const ADRankFourTensor & rotated_elasticity_tensor,
                                        const ADRankTwoTensor & lagrangian_strain_tensor);

  virtual ADRealVectorValue computeNHStrainEnergy(const ADRankTwoTensor & be_bar);

  //brakets
  virtual ADReal braket(const ADReal & x);
  virtual ADReal braketDerivative(const ADReal & x);
  virtual ADRankTwoTensor truncExp(const ADRankTwoTensor & x);
  virtual ADRankTwoTensor truncExpDerivative(const ADRankTwoTensor & x);

  virtual void viscoPlasticUpdate();

  ////////////////////////////////////////////
  //rest of forward declarations
  const ADVariableValue &_T;
  const MaterialPropertyName &_bulk_name;
  const ADMaterialProperty<Real> &_bulk;

  const MaterialPropertyName &_poisson_name;
  const ADMaterialProperty<Real> &_poisson;

  ADMaterialProperty<RankTwoTensor> &_F;
  const MaterialProperty<RankTwoTensor> & _F_old;
  ADMaterialProperty<Real> &_J;
  ADMaterialProperty<Real> &_Je;
  const MaterialProperty<Real> &_J_old;

  ADMaterialProperty<RankTwoTensor> &_Fe;
  ADMaterialProperty<RankTwoTensor> &_Fp;
  const MaterialProperty<RankTwoTensor> &_Fe_old;
  const MaterialProperty<RankTwoTensor> &_Fp_old;

  ADMaterialProperty<RankTwoTensor> & _be_bar;
  const MaterialProperty<RankTwoTensor> & _be_bar_old;
  ADMaterialProperty<RankTwoTensor> &_Cp;
  ADMaterialProperty<RankTwoTensor> & _Np;
  
  const std::string _ep_name;
  ADMaterialProperty<Real> & _ep;
  const MaterialProperty<Real> & _ep_old;
  ADMaterialProperty<Real> &_ep_dot;

  ADMaterialProperty<RankTwoTensor> &_F_incremental;
  const MaterialProperty<RankTwoTensor> &_F_incremental_old;

  const ADMaterialProperty<RankTwoTensor> &_R_incremental;
  const ADMaterialProperty<RankTwoTensor> &_U_incremental;

  MaterialBase * _flow_stress_material;
  const std::string _flow_stress_name;
  ADMaterialProperty<Real> & _Hist;
  const MaterialProperty<Real> &_Hist_old;
  
  const ADMaterialProperty<Real> & _H;
  const ADMaterialProperty<Real> & _dH;
  const ADMaterialProperty<Real> & _d2H;

  const MaterialPropertyName &_De_name;
  const ADMaterialProperty<Real> &_De;

  const MaterialPropertyName &_Dp_name;
  const ADMaterialProperty<Real> &_Dp;

  ADMaterialProperty<RankTwoTensor> &_cauchy;
  ADMaterialProperty<RankTwoTensor> &_pk1;
  ADMaterialProperty<RankTwoTensor> &_pk2;

  const bool _exp_approx;
  const bool _penalize_shear;
  const std::string _stress_model;

  //for artificial viscosity

  const bool _use_av;
  const Real _C0;
  const Real _C1;
  const MaterialPropertyName &_h_min_name;
  const MaterialProperty<Real> &_h_min;
  const MaterialPropertyName &_density_name;
  const ADMaterialProperty<Real> &_density;
  ADMaterialProperty<Real> * const _p_av;
  
  const std::string _constitutive_model;
  const MaterialPropertyName &_elasticity_tensor_name;

  //for SVK
  const ADMaterialProperty<RankFourTensor> * const _elasticity_tensor;
  const bool _viscoplastic;
  const MaterialPropertyName &_vp_flow_resistance_name;
  const ADMaterialProperty<Real> * const _vp_flow_resistance;
  const MaterialPropertyName &_vp_reference_rate_name;
  const ADMaterialProperty<Real> * const _vp_reference_rate;
  const MaterialPropertyName &_vp_rate_exponent_name;
  const ADMaterialProperty<Real> * const _vp_rate_exponent;
  const MaterialPropertyName &_vp_yield_function_name;
  const ADMaterialProperty<Real> * const _vp_yield_function;
  const MaterialPropertyName &_xi_name;
  const ADMaterialProperty<Real> * const _xi;

private:
    //nothing here
    //hi
    //hey
};
