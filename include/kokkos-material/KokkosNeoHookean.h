#pragma once

#include "KokkosMaterial.h"
#include "NeoHookean.h"

/** Compressible neo-Hookean solid, embedded in 3D for reduced dimensional meshes. */
class KokkosNeoHookean : public Moose::Kokkos::Material
{
public:
  static InputParameters validParams();
  KokkosNeoHookean(const InputParameters & parameters);

  template <typename Derived>
  KOKKOS_FUNCTION void computeQpProperties(unsigned int qp, Datum & datum) const
  {
    Real F[3][3] = {{1,0,0},{0,1,0},{0,0,1}};
    for (unsigned int i = 0; i < _ndisp; ++i)
    {
      const auto grad = _grad_disp(datum, qp, i);
      for (unsigned int a = 0; a < 3; ++a)
        F[i][a] += grad(a);
    }
    Real J, energy, P[3][3], A[3][3][3][3];
    if (!ml::neoHookean(F, J, _bulk, _shear, energy, P, A))
      Kokkos::abort("KokkosNeoHookean requires finite det(F) > 0.");
    _energy(datum, qp) = energy;
    for (unsigned int i = 0; i < 3; ++i){
      for (unsigned int a = 0; a < 3; ++a)
      {
        _pk1(datum, qp)(i,a) = P[i][a];
        for (unsigned int k = 0; k < 3; ++k)
          for (unsigned int b = 0; b < 3; ++b)
            _dpk1_dF(datum, qp)(i,a,k,b) = A[i][a][k][b];
      }
    }

    // Cauchy stress: sigma = P F^T / J.
    for (unsigned int i = 0; i < 3; ++i)
      for (unsigned int j = 0; j < 3; ++j)
      {
        Real sigma = 0;
        for (unsigned int k = 0; k < 3; ++k)
          sigma += P[i][k] * F[j][k];
        _sigma(datum, qp)(i,j) = sigma / J;
      }
  }

protected:
  const unsigned int _ndisp;
  const Moose::Kokkos::VariableGradient _grad_disp;
  const Real _bulk;
  const Real _shear;
  Moose::Kokkos::MaterialProperty<Real> _energy;
  Moose::Kokkos::MaterialProperty<Real, 2> _pk1;
  Moose::Kokkos::MaterialProperty<Real, 4> _dpk1_dF;
  Moose::Kokkos::MaterialProperty<Real, 2> _sigma;
};
