#pragma once

#include "KokkosMaterial.h"

/** Extract a zero-based component of a rank-two Kokkos material property. */
class KokkosTensorComponent : public Moose::Kokkos::Material
{
public:
  static InputParameters validParams();
  KokkosTensorComponent(const InputParameters & parameters);

  template <typename Derived>
  KOKKOS_FUNCTION void computeQpProperties(const unsigned int qp, Datum & datum) const
  {
    const auto tensor = _tensor(datum, qp);
    if (_row >= tensor.n(0) || _column >= tensor.n(1))
      Kokkos::abort("KokkosTensorComponent component is outside the tensor dimensions.");
    _extracted(datum, qp) = tensor(_row, _column);
  }

protected:
  const Moose::Kokkos::MaterialProperty<Real, 2> _tensor;
  unsigned int _row;
  unsigned int _column;
  Moose::Kokkos::MaterialProperty<Real> _extracted;
};
