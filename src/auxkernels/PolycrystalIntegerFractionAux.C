#include "PolycrystalIntegerFractionAux.h"
#include "MicrostructureID.h"

registerMooseObject("mlApp", PolycrystalIntegerFractionAux);

InputParameters
PolycrystalIntegerFractionAux::validParams()
{
  InputParameters params = AuxKernel::validParams();
  params.addClassDescription("read initial RDX fraction from CSV using tessellation of density_i");
  params.addRequiredParam<std::string>("csv_fraction", "csv_fraction");
  params.addRequiredParam<std::string>("csv_fraction_pore", "csv_fraction_pore");
  params.addParam<std::string>("microstructure_id_name", "microstructure_id", "Extra element integer label");

  //we need to add an input that is consistent with the placeholder MicroID assigned in the UO
  params.addRequiredParam<unsigned int>("bulk_MicroID", "bulk_MicroID");
  params.addRequiredParam<Real>("bulk_RDX_fraction", "bulk_RDX_fraction");
  params.addRequiredParam<std::vector<unsigned int>>("range_pore", "range_pore");

  //for using loaded microstructure
  params.addParam<bool>("use_loaded_microstructure", false, "use_loaded_microstructure");
  params.addCoupledVar("loaded_microstructure", "loaded_microstructure");

  //for segmentation
  params.addParam<Real>("pore_limit", 0.25, "pore_limit");
  params.addParam<Real>("bulk_limit", 1.77, "bulk_limit");
  return params;
}

PolycrystalIntegerFractionAux::PolycrystalIntegerFractionAux(const InputParameters & parameters)
  : AuxKernel(parameters),
    _csv_fraction(getParam<std::string>("csv_fraction")),
    _csv_fraction_pore(getParam<std::string>("csv_fraction_pore")),
    _micro_id_index(_mesh.getMesh().get_elem_integer_index(getParam<std::string>("microstructure_id_name"))),

    //for bulk assignment
    _bulk_MicroID(getParam<unsigned int>("bulk_MicroID")),
    _bulk_RDX_fraction(getParam<Real>("bulk_RDX_fraction")),
    _range_pore(getParam<std::vector<unsigned int>>("range_pore")),
    _use_loaded_microstructure(getParam<bool>("use_loaded_microstructure")),
    _loaded_microstructure(isCoupled("loaded_microstructure") ? &coupledValue("loaded_microstructure") : nullptr),
    _pore_limit(getParam<Real>("pore_limit")),
    _bulk_limit(getParam<Real>("bulk_limit"))
{
    _csv_total_fraction = readCSV(_csv_fraction);
    if (_csv_total_fraction.empty() || _csv_total_fraction.front().empty())
      mooseError("Empty integer MicroID lookup table: _csv_total_fraction");
    _csv_total_fraction_pore = readCSV(_csv_fraction_pore);
    if (_csv_total_fraction_pore.empty() || _csv_total_fraction_pore.front().empty())
      mooseError("Empty integer MicroID lookup table: _csv_total_fraction_pore");
}

Real
PolycrystalIntegerFractionAux::computeValue()
{
    const std::vector<Real> first_col = _csv_total_fraction[0];
    const std::vector<Real> first_col_pore = _csv_total_fraction_pore[0];

    const auto id = MicrostructureID::get(*_sys.feProblem().mesh().elemPtr(_current_elem->id()), _micro_id_index);
    const bool is_pore = id >= _range_pore.front() && id <= _range_pore.back();
    if (is_pore)
      // Raw pore CSV rows include the velocity in column zero, hence the +1 offset.
      return MicrostructureID::tableValue(first_col_pore, id - _range_pore.front() + 1,
                                          *_current_elem, id, _t, _csv_fraction_pore);
    if (id == _bulk_MicroID)
      return _bulk_RDX_fraction;
    return MicrostructureID::tableValue(first_col, id, *_current_elem, id, _t, _csv_fraction);
}

std::vector<std::vector<Real>>
PolycrystalIntegerFractionAux::readCSV(const std::string csv_file_name){
  std::ifstream file(csv_file_name);
  if (!file.is_open()){
    mooseError("can't open CSV file");
  }

  std::vector<std::vector<Real>> data;
  std::string line;
  while (std::getline(file, line)){
    std::vector<Real> row;
    std::stringstream ss(line);
    std::string value;

    while (std::getline(ss, value, ',')){
      try{
        row.push_back(static_cast<Real>(std::stod(value)));
      }
      catch (const std::invalid_argument &e){
        mooseError("Invalid value in CSV file: " + value);
      }
    }
    data.push_back(row);
  }
  file.close();
  return data;
}