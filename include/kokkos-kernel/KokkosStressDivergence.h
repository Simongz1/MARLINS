#pragma once

#include "KokkosKernelGrad.h"

/** Total Lagrangian Cartesian equilibrium: integral P_iJ grad(test)_J dV. */
class KokkosStressDivergence : public Moose::Kokkos::KernelGrad
{
public:
  static InputParameters validParams();
  KokkosStressDivergence(const InputParameters & parameters);

  template <typename Derived>
  KOKKOS_FUNCTION Moose::Kokkos::Real3
  precomputeQpResidual(unsigned int qp, AssemblyDatum & datum) const
  {
    Moose::Kokkos::Real3 result(0);
    for (unsigned int a = 0; a < 3; ++a)
      result(a) = _pk1(datum, qp)(_component, a);
    return result;
  }

  template <typename Derived>
  KOKKOS_FUNCTION Moose::Kokkos::Real3
  precomputeQpJacobian(unsigned int j, unsigned int qp, AssemblyDatum & datum) const
  {
    return tangent(j, _component, qp, datum);
  }

  template <typename Derived>
  KOKKOS_FUNCTION Moose::Kokkos::Real3
  precomputeQpOffDiagJacobian(unsigned int j, unsigned int jvar,
                            unsigned int qp, AssemblyDatum & datum) const
  {
    for (unsigned int c = 0; c < _ndisp; ++c)
      if (jvar == _disp_var[c])
        return tangent(j, c, qp, datum);
    return Moose::Kokkos::Real3(0);
  }

protected:
  KOKKOS_FUNCTION Moose::Kokkos::Real3
  tangent(unsigned int j, unsigned int c, unsigned int qp, AssemblyDatum & datum) const
  {
    Moose::Kokkos::Real3 result(0);
    const auto grad = _grad_phi(datum, j, qp);
    for (unsigned int a = 0; a < 3; ++a)
      for (unsigned int b = 0; b < 3; ++b)
        result(a) += _dpk1_dF(datum, qp)(_component, a, c, b) * grad(b);
    return result;
  }

  const unsigned int _component;
  const unsigned int _ndisp;
  unsigned int _disp_var[3] = {};
  const Moose::Kokkos::MaterialProperty<Real, 2> _pk1;
  const Moose::Kokkos::MaterialProperty<Real, 4> _dpk1_dF;
};
