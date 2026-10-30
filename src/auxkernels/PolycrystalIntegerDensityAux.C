#include "PolycrystalIntegerDensityAux.h"
#include "MicrostructureID.h"

registerMooseObject("mlApp", PolycrystalIntegerDensityAux);

InputParameters
PolycrystalIntegerDensityAux::validParams()
{
  InputParameters params = AuxKernel::validParams();
  params.addClassDescription("read density from CSV using tessellation of density_i");
  params.addRequiredParam<std::string>("csv_density", "csv_density");
  params.addParam<std::string>("microstructure_id_name", "microstructure_id", "Extra element integer label");
  params.addRequiredParam<Real>("density_scaling", "density_scaling");

  //parameters for bulk grains
  params.addRequiredParam<unsigned int>("bulk_MicroID", "bulk_MicroID");
  params.addRequiredParam<Real>("bulk_RDX_density", "bulk_RDX_density");
  params.addRequiredParam<std::string>("csv_density_pore", "csv_density_pore");
  params.addRequiredParam<std::vector<unsigned int>>("range_pore", "range_pore");

  //for using loaded microstructure
  params.addParam<bool>("use_loaded_microstructure", false, "use_loaded_microstructure");
  params.addCoupledVar("loaded_microstructure", "loaded_microstructure");

  //for segmentation
  params.addParam<Real>("pore_limit", 0.25, "pore_limit");
  params.addParam<Real>("bulk_limit", 1.77, "bulk_limit");
  return params;
}

PolycrystalIntegerDensityAux::PolycrystalIntegerDensityAux(const InputParameters & parameters)
  : AuxKernel(parameters),
    _csv_density(getParam<std::string>("csv_density")),
    _csv_density_pore(getParam<std::string>("csv_density_pore")),
    _micro_id_index(_mesh.getMesh().get_elem_integer_index(getParam<std::string>("microstructure_id_name"))),
    _density_scaling(getParam<Real>("density_scaling")),

    //parameters for bulk grains
    _bulk_MicroID(getParam<unsigned int>("bulk_MicroID")),
    _bulk_RDX_density(getParam<Real>("bulk_RDX_density")),

    //get params for pores, these are set as global params
    _range_pore(getParam<std::vector<unsigned int>>("range_pore")),
    _use_loaded_microstructure(getParam<bool>("use_loaded_microstructure")),
    _loaded_microstructure(isCoupled("loaded_microstructure") ? &coupledValue("loaded_microstructure") : nullptr),
    _pore_limit(getParam<Real>("pore_limit")),
    _bulk_limit(getParam<Real>("bulk_limit"))
{
    _csv_total_density = readCSV(_csv_density);
    if (_csv_total_density.empty() || _csv_total_density.front().empty())
      mooseError("Empty integer MicroID lookup table: _csv_total_density");
    _csv_total_density_pore = readCSV(_csv_density_pore);
    if (_csv_total_density_pore.empty() || _csv_total_density_pore.front().empty())
      mooseError("Empty integer MicroID lookup table: _csv_total_density_pore");
}

Real
PolycrystalIntegerDensityAux::computeValue()
{
    std::vector<Real> first_col = _csv_total_density[0];
    std::vector<Real> first_col_pore = _csv_total_density_pore[0];

    //evaluate denisty_i before reading data
    //we need to create the cases

    const auto id = MicrostructureID::get(*_sys.feProblem().mesh().elemPtr(_current_elem->id()), _micro_id_index);
    const bool is_pore = id >= _range_pore.front() && id <= _range_pore.back();
    Real pred_density;
    if (is_pore)
      // Raw pore CSV rows include the velocity in column zero, hence the +1 offset.
      pred_density = MicrostructureID::tableValue(first_col_pore, id - _range_pore.front() + 1,
                                                 *_current_elem, id, _t, _csv_density_pore);
    else if (id == _bulk_MicroID)
      pred_density = _bulk_RDX_density;
    else
      pred_density = MicrostructureID::tableValue(first_col, id, *_current_elem, id, _t, _csv_density);
    return _density_scaling * pred_density;
}

std::vector<std::vector<Real>>
PolycrystalIntegerDensityAux::readCSV(const std::string csv_file_name){
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