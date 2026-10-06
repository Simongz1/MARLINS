#pragma once

#include <cmath>

#ifdef MOOSE_KOKKOS_SCOPE
#include "Kokkos_Core.hpp"
#define ML_NEOHOOKEAN_FUNCTION KOKKOS_INLINE_FUNCTION
#else
#define ML_NEOHOOKEAN_FUNCTION inline
#endif

namespace ml
{
ML_NEOHOOKEAN_FUNCTION bool
neoHookean(const double F[3][3], double & J, double bulk, double shear,
           double & energy, double P[3][3], double A[3][3][3][3])
{
  double H[3][3]; // Cofactor, then inverse transpose

  for (unsigned int i = 0; i < 3; ++i){
    for (unsigned int a = 0; a < 3; ++a){
      H[i][a] = F[(i+1)%3][(a+1)%3] * F[(i+2)%3][(a+2)%3]
              - F[(i+1)%3][(a+2)%3] * F[(i+2)%3][(a+1)%3];
    }   
  }
  //compute Jacobian from cofactor matrix contracted with deformation gradient

  J = F[0][0]*H[0][0] + F[0][1]*H[0][1] + F[0][2]*H[0][2];

  //check whether the jacobian is well defined
  if (!(J > 0) || !std::isfinite(J)){
    return false;
  }
  
  //compute first invariant
  double I1 = 0;
  for (unsigned int i = 0; i < 3; ++i){
    for (unsigned int a = 0; a < 3; ++a){
      H[i][a] /= J;
      I1 += F[i][a]*F[i][a];
    }
  }
    
  double q = std::pow(J, -2.0/3.0);
  double v = bulk*J*(J-1);

  energy = 0.5*bulk*(J-1)*(J-1) + 0.5*shear*(q*I1-3);

  for (unsigned int i = 0; i < 3; ++i)
    for (unsigned int a = 0; a < 3; ++a)
    {
      P[i][a] = shear * q * (F[i][a] - I1 / 3 * H[i][a]) + v * H[i][a];

      for (unsigned int k = 0; k < 3; ++k)
        for (unsigned int b = 0; b < 3; ++b)
          A[i][a][k][b] = shear * q * ((i == k && a == b)
              - 2.0 / 3 * (F[i][a] * H[k][b] + H[i][a] * F[k][b])
              + 2.0 / 9 * I1 * H[i][a] * H[k][b] + I1 / 3 * H[i][b] * H[k][a])
              + bulk * J * (2 * J - 1) * H[i][a] * H[k][b] - v * H[i][b] * H[k][a];
    }
  return true;
}
} // namespace ml

#undef ML_NEOHOOKEAN_FUNCTION
