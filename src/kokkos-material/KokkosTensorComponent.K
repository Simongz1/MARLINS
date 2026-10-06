#include "KokkosTensorComponent.h"

registerKokkosMaterial("mlApp", KokkosTensorComponent);

InputParameters
KokkosTensorComponent::validParams()
{
  auto params = Material::validParams();
  params.addClassDescription("Extract a component of a rank-two Kokkos tensor into a Real property.");
  params.addRequiredParam<MaterialPropertyName>("tensor_name", "Tensor material property to read.");
  params.addRequiredParam<std::vector<int>>("component", "Zero-based row and column indices.");
  params.addRequiredParam<MaterialPropertyName>("output_name", "Scalar material property to declare.");
  return params;
}

KokkosTensorComponent::KokkosTensorComponent(const InputParameters & parameters)
  : Material(parameters),
    _tensor(getKokkosMaterialProperty<Real, 2>("tensor_name")),
    _row(0),
    _column(0),
    _extracted(declareKokkosProperty<Real>("output_name"))
{
  const auto & component = getParam<std::vector<int>>("component");
  if (component.size() != 2)
    paramError("component", "Supply exactly two indices: row and column.");
  if (component[0] < 0 || component[1] < 0)
    paramError("component", "Indices must be nonnegative (zero-based).");
  _row = component[0];
  _column = component[1];
}
