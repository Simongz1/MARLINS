#pragma once
#include "ADMaterial.h"

class ADCompressionHeating : public ADMaterial
{
public:
    ADCompressionHeating(const InputParameters & parameters);
    static InputParameters validParams();

protected:
    virtual void computeQpProperties() override;

private:
    const ADVariableValue &_temperature;
    const ADMaterialProperty<RankTwoTensor> &_F;
    const MaterialProperty<RankTwoTensor> &_F_old;
    const ADMaterialProperty<Real> &_Je;
    ADMaterialProperty<Real> &_q_elastic;
    //
    const MaterialPropertyName _thermal_expansion_name;
    const MaterialPropertyName _bulk_modulus_name;
    ADMaterialProperty<Real> &_thermal_expansion;
    ADMaterialProperty<Real> &_bulk_modulus;
};