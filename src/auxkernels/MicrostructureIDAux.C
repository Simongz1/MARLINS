#include "MicrostructureIDAux.h"
#include "MicrostructureID.h"
#include "SystemBase.h"
#include "FEProblemBase.h"

registerMooseObject("mlApp", MicrostructureIDAux);

InputParameters
MicrostructureIDAux::validParams()
{
  InputParameters params = AuxKernel::validParams();
  params.addClassDescription("Display an original-region integer MicroID without using an FE field for lookup.");
  params.addParam<std::string>("microstructure_id_name", "microstructure_id", "Extra element integer label");
  return params;
}

MicrostructureIDAux::MicrostructureIDAux(const InputParameters & parameters)
  : AuxKernel(parameters),
    _micro_id_index(_mesh.getMesh().get_elem_integer_index(getParam<std::string>("microstructure_id_name")))
{
  if (isNodal())
    paramError("variable", "Use an elemental CONSTANT MONOMIAL visualization variable.");
}

Real
MicrostructureIDAux::computeValue()
{
  return MicrostructureID::get(*_sys.feProblem().mesh().elemPtr(_current_elem->id()), _micro_id_index);
}
