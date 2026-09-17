#pragma once

#include "ADComputeStressBase.h"
#include "ElasticityTensorTools.h"
#include "ADSingleVariableReturnMappingSolution.h"
#include "Function.h"
#include "DerivativeMaterialInterface.h"

/* This class implements the Simo-Hughes style J2 plasticity */
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

  /// @{ The return mapping residual and derivative
  virtual Real computeReferenceResidual(const ADReal & effective_trial_stress,
                                        const ADReal & scalar) override;
  virtual ADReal computeResidual(const ADReal & effective_trial_stress, const ADReal & scalar) override;
  virtual ADReal computeDerivative(const ADReal & effective_trial_stress, const ADReal & scalar) override;

  //begin the body
  const ADVariableValue &_T;
  const MaterialPropertyName &_bulk_name;
  const ADMaterialProperty<Real> &_bulk;

  const MaterialPropertyName &_poisson_name;
  const ADMaterialProperty<Real> &_poisson;

  ADMaterialProperty<RankTwoTensor> &_F;
  const MaterialProperty<RankTwoTensor> & _F_old;

  ADMaterialProperty<RankTwoTensor> &_Fe;
  ADMaterialProperty<RankTwoTensor> &_Fp;

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
  
private:
    //nothing here
    //hi
};