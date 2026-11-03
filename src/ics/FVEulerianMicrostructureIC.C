#include "FVEulerianMicrostructureIC.h"
#include "MISTnetXUtils.h"
#include "MicrostructureID.h"
#include "FEProblemBase.h"
registerMooseObject("mlApp",FVEulerianMicrostructureIC);
InputParameters
FVEulerianMicrostructureIC::validParams()
{
  auto p=InitialCondition::validParams();
  p.addRequiredParam<MooseEnum>("quantity",MooseEnum("rho thermal diagonal_F reference_volume phi Y1 X Y"),"Conserved initial field");
  p.addRequiredParam<std::string>("csv_directory","Directory containing the reference density/fraction CSVs");
  return p;
}
FVEulerianMicrostructureIC::FVEulerianMicrostructureIC(const InputParameters & p)
 : InitialCondition(p),_quantity(getParam<MooseEnum>("quantity")),
 _density_index(_fe_problem.mesh().getMesh().get_elem_integer_index("microstructure_id")),
 _prediction_index(_fe_problem.mesh().getMesh().get_elem_integer_index("legacy_prediction_id"))
{
  const auto dir=getParam<std::string>("csv_directory")+"/";
  _density=MISTnetXUtils::readCSV(dir+"densities_new.csv").at(0);
  _pore_density=MISTnetXUtils::readCSV(dir+"density_pore.csv").at(0);
  _fraction=MISTnetXUtils::readCSV(dir+"fractions_new.csv").at(0);
  _pore_fraction=MISTnetXUtils::readCSV(dir+"fraction_pore.csv").at(0);
}
Real
FVEulerianMicrostructureIC::value(const Point & p)
{
  const auto id=MicrostructureID::get(*_current_elem,_density_index);
  const auto pred=MicrostructureID::get(*_current_elem,_prediction_index);
  const bool pore=id>=101 && id<=103;
  const Real rho=.001*(id==99 ? 1820 : (pore?_pore_density.at(id-101+1):_density.at(id)));
  const Real phi=id==99?1:(pore?_pore_fraction.at(id-101+1):_fraction.at(id));
  // Match the legacy UO: initial Y1 uses its rounded prediction ID, whereas
  // the independently stored fraction uses the truncated density-table ID.
  const Real y=(pred==99 || (pred>=101 && pred<=103))?1:_fraction.at(pred);
  if(_quantity=="rho" || _quantity=="diagonal_F") return rho;
  if(_quantity=="thermal") return rho*.002355592*300;
  if(_quantity=="reference_volume") return 1;
  if(_quantity=="phi") return rho*phi;
  if(_quantity=="Y1") return rho*y;
  return rho*p(_quantity=="X"?0:1);
}
