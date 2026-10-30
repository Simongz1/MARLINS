#include "PolycrystalDensityIntegerUO.h"
#include "Function.h"
#include "MicrostructureID.h"
#include "MooseApp.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <limits>
#include <numeric>
#include <sstream>
#include <unordered_map>
#include <utility>
#include "libmesh/replicated_mesh.h"


namespace
{
// SplitMix64: deterministic uniform values in [0,1), independent of MPI rank.
Real integerElementRandom(std::uint64_t id, std::uint64_t stream)
{
  std::uint64_t x = id ^ (stream * UINT64_C(0x9e3779b97f4a7c15)) ^ UINT64_C(1234);
  x += UINT64_C(0x9e3779b97f4a7c15);
  x = (x ^ (x >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
  x = (x ^ (x >> 27)) * UINT64_C(0x94d049bb133111eb);
  x ^= x >> 31;
  return static_cast<Real>(x >> 11) * (1.0 / 9007199254740992.0);
}

class IntegerCenterTree
{
public:
  using Hit = std::pair<Real, unsigned int>;
  using Hits = std::pair<Hit, Hit>;
  explicit IntegerCenterTree(const std::vector<Point> & points) : _points(points), _order(points.size())
  {
    std::iota(_order.begin(), _order.end(), 0);
    build(0, _order.size(), 0);
  }
  Hits nearestTwo(const Point & p) const
  {
    const Hit missing(std::numeric_limits<Real>::infinity(),
                      std::numeric_limits<unsigned int>::max());
    Hits hits(missing, missing);
    query(p, 0, _order.size(), 0, hits);
    return hits;
  }
private:
  void build(std::size_t lo, std::size_t hi, unsigned int depth)
  {
    if (lo == hi)
      return;
    const auto mid = lo + (hi - lo) / 2;
    const auto axis = depth % 3;
    std::nth_element(_order.begin() + lo, _order.begin() + mid, _order.begin() + hi,
                     [&](unsigned int a, unsigned int b) {
                       return std::make_pair(_points[a](axis), a) <
                              std::make_pair(_points[b](axis), b);
                     });
    build(lo, mid, depth + 1);
    build(mid + 1, hi, depth + 1);
  }
  void query(const Point & p, std::size_t lo, std::size_t hi,
             unsigned int depth, Hits & hits) const
  {
    if (lo == hi)
      return;
    const auto mid = lo + (hi - lo) / 2;
    const auto id = _order[mid];
    Real d2 = 0;
    for (unsigned int j = 0; j < 3; ++j)
    {
      const Real d = p(j) - _points[id](j);
      d2 += d * d;
    }
    const Hit candidate(d2, id);
    if (candidate < hits.first)
    {
      hits.second = hits.first;
      hits.first = candidate;
    }
    else if (candidate < hits.second)
      hits.second = candidate;
    const Real delta = p(depth % 3) - _points[id](depth % 3);
    if (delta <= 0)
    {
      query(p, lo, mid, depth + 1, hits);
      if (delta * delta <= hits.second.first)
        query(p, mid + 1, hi, depth + 1, hits);
    }
    else
    {
      query(p, mid + 1, hi, depth + 1, hits);
      if (delta * delta <= hits.second.first)
        query(p, lo, mid, depth + 1, hits);
    }
  }
  const std::vector<Point> & _points;
  std::vector<unsigned int> _order;
};
}

registerMooseObject("mlApp", PolycrystalDensityIntegerUO);

InputParameters
PolycrystalDensityIntegerUO::validParams()
{
  InputParameters params = GeneralUserObject::validParams();
  params.addParam<std::string>("microstructure_id_name", "microstructure_id", "Pre-registered extra element integer");
  params.addRequiredParam<unsigned int>("num_grains", "Number of Voronoi seeds");
  params.addRequiredParam<std::vector<unsigned int>>("target_grains", "target_grains");
  params.addRequiredParam<std::vector<unsigned int>>("range_in", "range_in");
  params.addRequiredParam<std::vector<unsigned int>>("range_out", "range_out");
  params.addRequiredParam<bool>("generate_matrix", "generate_matrix");
  params.addRequiredParam<Real>("max_grain_size", "max_grain_size");
  params.addRequiredParam<Real>("min_center_spacing", "min_center_spacing");
  params.addRequiredParam<Real>("matrix_thickness", "matrix_thickness");
  params.addRequiredParam<std::vector<unsigned int>>("sizes", "sizes");
  params.addRequiredParam<std::vector<Real>>("sizes_fraction", "sizes_fraction");

  
  params.addRequiredParam<std::string>("csv_fraction", "csv_fraction");
  params.addRequiredParam<std::string>("csv_fraction_pore", "csv_fraction_pore");


  params.addRequiredParam<bool>("bulk_grains", "bulk_grains");
  params.addRequiredParam<unsigned int>("n_pores", "n_pores");

  params.addRequiredParam<unsigned int>("bulk_MicroID", "bulk_MicroID");
  params.addRequiredParam<Real>("bulk_RDX_fraction", "bulk_RDX_fraction");
  params.addRequiredParam<std::vector<unsigned int>>("range_pore", "range_pore");
  params.addRequiredParam<Real>("pore_RDX_fraction", "pore_RDX_fraction");
  params.addParam<Real>("pore_probability", 0.01, "pore_probability"); //defaul value

  params.addParam<bool>("use_loaded_microstructure", false, "use_loaded_microstructure");
  params.addParam<FunctionName>("loaded_microstructure", "loaded_microstructure", "loaded_microstructure");
  params.addParam<Real>("pore_limit", 0.25, "pore_limit");
  params.addParam<Real>("bulk_limit", 1.77, "bulk_limit");
  return params;
}

PolycrystalDensityIntegerUO::PolycrystalDensityIntegerUO(const InputParameters & params)
  : GeneralUserObject(params), 
    _micro_id_name(getParam<std::string>("microstructure_id_name")),
    _num_grains(getParam<unsigned int>("num_grains")),
    _target_grains(getParam<std::vector<unsigned int>>("target_grains")),
    _range_in(getParam<std::vector<unsigned int>>("range_in")),
    _range_out(getParam<std::vector<unsigned int>>("range_out")),
    _generate_matrix(getParam<bool>("generate_matrix")),
    _max_grain_size(getParam<Real>("max_grain_size")),
    _min_center_spacing(getParam<Real>("min_center_spacing")),
    _matrix_thickness(getParam<Real>("matrix_thickness")),
    _sizes(getParam<std::vector<unsigned int>>("sizes")),
    _sizes_fraction(getParam<std::vector<Real>>("sizes_fraction")),
    _csv_fraction(getParam<std::string>("csv_fraction")),
    _csv_fraction_pore(getParam<std::string>("csv_fraction_pore")),
    _bulk_grains(getParam<bool>("bulk_grains")),
    _n_pores(getParam<unsigned int>("n_pores")),

    _bulk_MicroID(getParam<unsigned int>("bulk_MicroID")),
    _bulk_RDX_fraction(getParam<Real>("bulk_RDX_fraction")),

    _range_pore(getParam<std::vector<unsigned int>>("range_pore")),
    _pore_RDX_fraction(getParam<Real>("pore_RDX_fraction")),
    _pore_probability(getParam<Real>("pore_probability")),

    _use_loaded_microstructure(getParam<bool>("use_loaded_microstructure")),
    _loaded_microstructure_name(getParam<FunctionName>("loaded_microstructure")),
    _pore_limit(getParam<Real>("pore_limit")),
    _bulk_limit(getParam<Real>("bulk_limit"))
{
    _csv_total_fractions = readCSV(_csv_fraction);
    // Kept as an accepted input for compatibility; no pore CSV values are used.
    if (_csv_total_fractions.empty() || _csv_total_fractions.front().empty())
      paramError("csv_fraction", "CSV must have a nonempty first numeric row.");
    if (_num_grains == 0 || _sizes.size() < 2 || _sizes[0] == 0 || _sizes[1] == 0)
      paramError("sizes", "Require positive grain count and two positive particle radii.");
    if (_range_in.size() < 2 || _range_out.size() < 2 || _range_pore.empty())
      paramError("range_in", "Require two range_in/range_out endpoints and nonempty range_pore.");
    if (_range_in[0] > _range_in[1] || _range_out[0] > _range_out[1])
      paramError("range_in", "MicroID range endpoints must be ordered.");
    if (_pore_probability < 0 || _pore_probability > 1 || _min_center_spacing < 0)
      paramError("pore_probability", "Probability must be in [0,1] and spacing nonnegative.");
}

void
PolycrystalDensityIntegerUO::initialSetup(){

  if (_app.isRecovering() || _app.isRestarting()){
    mooseInfo("PolycrystalDensityIntegerUO is recovering or restarting, skipping initialSetup");
    return;
  }

  if (!dynamic_cast<const libMesh::ReplicatedMesh *>(&_fe_problem.mesh().getMesh()))
    mooseError("PolycrystalDensityIntegerUO currently requires a replicated mesh for deterministic "
               "per-grain pore caps and shared-node initialization.");
  const auto start = std::chrono::steady_clock::now();
  const auto elapsed = [&]() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count();
  };
  mooseInfo("PolycrystalDensityIntegerUO: beginning center placement");
  const BoundingBox bbox = MeshTools::create_bounding_box(_fe_problem.mesh().getMesh());
  const Point min_corner = bbox.min();
  const Point max_corner = bbox.max();

  _centers.clear();
  _centers.reserve(_num_grains);

  _radii.clear();
  _radii.reserve(_num_grains);

  if (_sizes.size() < 2)
    paramError("sizes", "At least two particle sizes are required.");
  if (_sizes_fraction.empty() || _sizes_fraction[0] < 0.0 || _sizes_fraction[0] > 1.0)
    paramError("sizes_fraction", "The first particle-size fraction must be between 0 and 1.");

  MooseRandom::seed(1234);

  const Function & loaded_function = getFunction(_loaded_microstructure_name);

  for (unsigned int i = 0; i < _num_grains; ++i)
  { 
    bool accepted = false;
    Point candidate;

    for (unsigned int attempt = 0; attempt < 1e3 && !accepted; ++attempt){

    const Real x = min_corner(0) + MooseRandom::rand() * (max_corner(0) - min_corner(0));
    const Real y = min_corner(1) + MooseRandom::rand() * (max_corner(1) - min_corner(1));
    const Real z = (_fe_problem.mesh().dimension() == 3)
                     ? min_corner(2) + MooseRandom::rand() * (max_corner(2) - min_corner(2))
                     : 0.0;
    candidate = Point(x, y, z);

    accepted = true;
    for (const auto & existing : _centers){
      const Real dist = (candidate - existing).norm();
      if (dist < _min_center_spacing){
        accepted = false;
        break;
      }
    }
    if (accepted){
      _centers.push_back(candidate);

      const Real r = MooseRandom::rand();
      if (r < _sizes_fraction[0]){
        _radii.push_back(_sizes[0]);
      }else{
        _radii.push_back(_sizes[1]);
      }
    }
    }
  }

  if (_centers.empty())
    mooseError("PolycrystalDensityIntegerUO was unable to place any particle centers.");

  if (_tid == 0){
     mooseInfo("Requested ",
               _num_grains,
               " Voronoi centers and generated ",
               _centers.size(),
               " in PolycrystalDensityIntegerUO. Next step is to assign defects inside grains and "
               "nanoPBXs at the interfaces");
  }

  IntegerCenterTree tree(_centers);
  std::vector<unsigned int> pore_counts(_centers.size(), 0);
  std::unordered_map<dof_id_type, std::pair<Real, unsigned int>> nodal_fractions;
  mooseInfo("PolycrystalDensityIntegerUO: center placement took ", elapsed(),
            " s; assigning fields with nearest-two-center search");

  auto & sys = _fe_problem.getAuxiliarySystem();
  auto & nl_sys = _fe_problem.getNonlinearSystem(0);
  auto & var = sys.getVariable(_tid, "density_i");
  auto & var_grainID = sys.getVariable(_tid, "grainID");
  auto & var_Y1 = nl_sys.getVariable(_tid, "Y1");
  const DofMap & dof_map = sys.system().get_dof_map();
  const DofMap & nl_dof_map = nl_sys.system().get_dof_map();








  std::vector<dof_id_type> dof_indices;
  std::vector<dof_id_type> dof_indices_grainID;
  std::vector<dof_id_type> dof_indices_Y1;
  const auto & data = _csv_total_fractions[0];
  const auto micro_id_index = _fe_problem.mesh().getMesh().get_elem_integer_index(_micro_id_name);

  for (const auto & elem : _fe_problem.mesh().getMesh().active_element_ptr_range())
  {
    if (elem->parent())
      mooseError("Integer microstructure initialization requires an initially unrefined mesh; "
                 "apply adaptive refinement after initialization.");
    Point centroid = elem->vertex_average();

    const auto nearest_two = tree.nearestTwo(centroid);
    const unsigned int nearest = nearest_two.first.second;
    const Real min_dist = std::sqrt(nearest_two.first.first);
    const Real second_min_dist = std::sqrt(nearest_two.second.first);
    bool is_pore = false;
    bool is_bulk = false;
    bool is_binder = false;
    bool is_grain = false;
    bool is_boundary = false;
    bool is_far = false;

    const Real boundary_gap = (second_min_dist - min_dist);
    


    const Real rand_value = integerElementRandom(elem->id(), 1);

    Real density_val;

    Real grainID = 0.0;



    Real loaded_density_value = 0.0;
    if (_bulk_grains){ //use_loaded_microstructure needs this
      if (_use_loaded_microstructure){
        loaded_density_value = loaded_function.value(0.0, centroid);

        is_pore = loaded_density_value <= _pore_limit;
        is_bulk = loaded_density_value >= _bulk_limit;
        is_binder = !is_pore && !is_bulk;
      }else{
        is_far = min_dist > _radii[nearest];
        is_boundary = boundary_gap < _matrix_thickness;
        is_grain = !is_boundary && !is_far;
        
        // Pores belong only to the nearest particle interior, not binder gaps.
        is_pore = is_grain && pore_counts[nearest] < _n_pores &&
                  integerElementRandom(elem->id(), 2) < _pore_probability;
        if (is_pore)
          ++pore_counts[nearest];
        is_bulk = (is_grain && !is_pore);
        is_binder = (!is_pore && !is_bulk);
      }

      if (is_pore){
        const unsigned int n_types = _range_pore.size();
        const unsigned int idx = static_cast<unsigned int>(std::floor(integerElementRandom(elem->id(), 3) * n_types)) % n_types;
        
        density_val = static_cast<Real>(_range_pore[idx]);
        grainID = static_cast<Real>(nearest + 1);
      }else if (is_bulk){
        density_val = static_cast<Real>(_bulk_MicroID);
        grainID = static_cast<Real>(nearest + 1);

      }

      else{
        density_val = _range_out[0] + rand_value * (_range_out[1] - _range_out[0]);
        grainID = 0; //this corresponds to binder
      }
    }else{
      is_far = min_dist > _radii[nearest];
      is_boundary = boundary_gap < _matrix_thickness;
      is_grain = !is_boundary && !is_far;

      density_val =
        is_grain ? (_range_in[0] + rand_value * (_range_in[1] - _range_in[0]))
                  : (_range_out[0] + rand_value * (_range_out[1] - _range_out[0]));
      grainID = is_grain ? static_cast<Real>(nearest + 1) : 0.0;
    }
    



    // Preserve the legacy density/fraction readers' truncation for generated binder IDs.
    // The integer label is authoritative; density_i is only a visualization copy.
    const auto micro_id = static_cast<dof_id_type>(density_val);
    elem->set_extra_integer(micro_id_index, micro_id);
    density_val = static_cast<Real>(micro_id);
    dof_map.dof_indices(elem, dof_indices, var.number());
    dof_map.dof_indices(elem, dof_indices_grainID, var_grainID.number());

    for (auto dof : dof_indices)
      if (dof >= sys.solution().first_local_index() && dof < sys.solution().last_local_index())
        sys.solution().set(dof, density_val);
    for (auto dof : dof_indices_grainID)
      if (dof >= sys.solution().first_local_index() && dof < sys.solution().last_local_index())
        sys.solution().set(dof, grainID);
    nl_dof_map.dof_indices(elem, dof_indices_Y1, var_Y1.number());

    if (dof_indices_Y1.empty())
      continue;

    const int call_density = static_cast<int>(std::round(density_val));

    const bool fraction_is_pore = (call_density >= _range_pore[0] && call_density <= _range_pore[1]);
    const bool fraction_is_bulk = (call_density == _bulk_MicroID);

    Real predicted_fraction = 0.0;
    if (fraction_is_pore || fraction_is_bulk)
    {
      predicted_fraction = fraction_is_pore ? _pore_RDX_fraction : _bulk_RDX_fraction;
    }
    else
    {
      predicted_fraction = MicrostructureID::tableValue(
          data, micro_id, *elem, micro_id, _t, _csv_fraction);
    }

    for (auto dof : dof_indices_Y1)
      if (dof >= nl_sys.solution().first_local_index() &&
          dof < nl_sys.solution().last_local_index())
      {
        auto & entry = nodal_fractions[dof];
        entry.first += predicted_fraction;
        ++entry.second;
      }
  }

  for (const auto & entry : nodal_fractions)
    nl_sys.solution().set(entry.first, entry.second.first / entry.second.second);
  sys.solution().close();
  nl_sys.solution().close();
  mooseInfo("PolycrystalDensityIntegerUO: setup completed in ", elapsed(), " s");
}
void
PolycrystalDensityIntegerUO::execute()
{}
void
PolycrystalDensityIntegerUO::initialize()
{}
void 
PolycrystalDensityIntegerUO::finalize()
{}

std::vector<std::vector<Real>>
PolycrystalDensityIntegerUO::readCSV(const std::string csv_file_name){
  std::ifstream file(csv_file_name);
  if (!file.is_open()){
    mooseError("PolycrystalDensityIntegerUO cannot open CSV file: ", csv_file_name);
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
      catch (const std::exception &e){
        mooseError("Invalid value in CSV file: " + value);
      }
    }
    if (!row.empty())
      data.push_back(std::move(row));
  }
  file.close();
  return data;
}

