#include "ADComputeIntPValRDXMISTERnetInteger.h"
#include "Distribution.h"
#include "MicrostructureID.h"
#include <limits>
#include "MooseRandom.h"

//call the util functions for reading CSV data
#include "MISTnetXUtils.h"

registerMooseObject("mlApp", ADComputeIntPValRDXMISTERnetInteger);

InputParameters
ADComputeIntPValRDXMISTERnetInteger::validParams()
{
  InputParameters params = Material::validParams();

  params.addClassDescription("compute MISTnetX predictions from interpolated values");

  //test: retrieve from name array
  params.addRequiredCoupledVar("v_components", "v_components");
  params.addRequiredCoupledVar("a_components", "a_components");

  params.addRequiredParam<Real>("thr_a", "acceleration threshold"); //deprecate this
  params.addRequiredParam<Real>("thr_v", "velocity threshold");

  //test: use gradient to compute activation

  params.addParam<std::string>("microstructure_id_name", "microstructure_id", "Extra element integer label");

  //CSV
  params.addRequiredParam<std::string>("csv_shock", "the name of the csv file with shock temperature values");
  params.addRequiredParam<std::string>("csv_react", "the name of the csv file with react temperature values");
  params.addRequiredParam<std::string>("csv_times", "the name of the csv file with times values");

  params.addRequiredParam<std::string>("csv_shock_pore", "csv_shock_pore");
  params.addRequiredParam<std::string>("csv_react_pore", "csv_react_pore");
  params.addRequiredParam<std::string>("csv_times_pore", "csv_times_pore");

  params.addRequiredParam<std::string>("csv_unreacted", "csv_unreacted");
  params.addRequiredParam<std::string>("csv_reacted", "csv_reacted");
  params.addRequiredCoupledVar("density_csv", "density_csv");

  //retrieve bulk ID
  params.addRequiredParam<unsigned int>("bulk_MicroID", "bulk_MicroID");
  params.addParam<unsigned int>("bulk_sensitivity", 20, "bulk_sensitivity");

  //retrieve range for pore IDS
  params.addRequiredParam<std::vector<unsigned int>>("range_pore", "range_pore");

  params.addRequiredParam<Real>("element_size", "element_size");
  params.addRequiredCoupledVar("tracking", "tracking");
  params.addParam<bool>("use_tabular_time", false, "use_tabular_time");
  params.addParam<bool>("use_distributions", false, "use_distributions");
  params.addParam<Real>("tau_react_scaling", 1., "tau_react_scaling");

  //add possible paramters for the us-up coefficients
  params.addParam<std::vector<Real>>("us_up_coeffs", {-0.286, 1.640, 1.249391, 5.575975}, "the coefficients for the polynomial fitting of the us-up relation from larger degree to smaller degree");
  return params;
}

ADComputeIntPValRDXMISTERnetInteger::ADComputeIntPValRDXMISTERnetInteger(
    const InputParameters & parameters)
  : Material(parameters),

  //rest
    _thr_a(getParam<Real>("thr_a")),
    _thr_v(getParam<Real>("thr_v")),
    _v_flag(declareADProperty<Real>("v_flag")),
    _v_flag_old(getMaterialPropertyOld<Real>("v_flag")),

    _temperature_mister_shock(declareProperty<Real>("temperature_mister_shock")),
    _temperature_mister_shock_old(getMaterialPropertyOld<Real>("temperature_mister_shock")),
    _temperature_mister_react(declareProperty<Real>("temperature_mister_react")),
    _temperature_mister_react_old(getMaterialPropertyOld<Real>("temperature_mister_react")),
    _micro_id_index(_mesh.getMesh().get_elem_integer_index(getParam<std::string>("microstructure_id_name"))),
    _called_up(declareADProperty<Real>("called_up")),
    _called_up_old(getMaterialPropertyOld<Real>("called_up")),
    _us(declareADProperty<Real>("us")),

    _csv_shock(getParam<std::string>("csv_shock")),
    _csv_react(getParam<std::string>("csv_react")),
    _csv_times(getParam<std::string>("csv_times")),

    //csv retrieval for pore
    _csv_shock_pore(getParam<std::string>("csv_shock_pore")),
    _csv_react_pore(getParam<std::string>("csv_react_pore")),
    _csv_times_pore(getParam<std::string>("csv_times_pore")),

    //declare time
    _time_react(declareADProperty<Real>("time_react")),
    _time_react_old(getMaterialPropertyOld<Real>("time_react")),

    _csv_unreacted(getParam<std::string>("csv_unreacted")),
    _csv_reacted(getParam<std::string>("csv_reacted")),
    _density(declareADProperty<Real>("density")),
    _density_csv(coupledValue("density_csv")),

    //bulk grains assignment
    _bulk_MicroID(getParam<unsigned int>("bulk_MicroID")),
    _bulk_sensitivity(getParam<unsigned int>("bulk_sensitivity")),
    _range_pore(getParam<std::vector<unsigned int>>("range_pore")),

    _rate_tracking(declareADProperty<Real>("rate_tracking")),
    _h(getParam<Real>("element_size")),
    _tracking(adCoupledValue("tracking")),
    _use_tabular_time(getParam<bool>("use_tabular_time")),
    _use_distributions(getParam<bool>("use_distributions")),

    //placeholder for distribution call
    _distribution_lower(nullptr),
    _distribution_upper(nullptr),
    _tau_react_scaling(getParam<Real>("tau_react_scaling")),
    //get parameters for us-up
    _coeffs(getParam<std::vector<Real>>("us_up_coeffs"))
{ 
  /////////////////////////////////////////////////////////

  const unsigned int n_v = coupledComponents("v_components");
  _v.reserve(n_v);
  for (unsigned int i = 0; i < n_v; ++i){
    _v.push_back(&adCoupledValue("v_components", i));
  }
    
  const unsigned int n_a = coupledComponents("a_components");
  _a.reserve(n_a);
  for (unsigned int i = 0; i < n_a; ++i){
    _a.push_back(&adCoupledValue("a_components", i));
  }

  //make the total CSV local
  const auto csv_total_shock = MISTnetXUtils::readCSV(_csv_shock);
  const auto csv_total_react = MISTnetXUtils::readCSV(_csv_react);
  
  if (_use_tabular_time){
    _csv_total_times = MISTnetXUtils::readCSV(_csv_times);
  }

  //read all the csv structures that are needed
  const auto csv_total_shock_pore = MISTnetXUtils::readCSV(_csv_shock_pore);
  const auto csv_total_react_pore = MISTnetXUtils::readCSV(_csv_react_pore);
  const auto csv_total_times_pore = MISTnetXUtils::readCSV(_csv_times_pore);
  const auto csv_total_pu = MISTnetXUtils::readCSV(_csv_unreacted);
  const auto csv_total_pr = MISTnetXUtils::readCSV(_csv_reacted);

  //use the csv function to form the velocity vectors
  _up_values = formVelocityVector(csv_total_shock);
  _up_values_pore = formVelocityVector(csv_total_shock_pore);

  //retrieve nanoPBX csv data using the new helper function
  _temperature_values_shock = MISTnetXUtils::formData(csv_total_shock);
  _temperature_values_react = MISTnetXUtils::formData(csv_total_react);

  if (_use_tabular_time){
    _time_values = MISTnetXUtils::formData(_csv_total_times);

  }

  //retrieve csv data for pore
  _temperature_values_shock_pore = MISTnetXUtils::formData(csv_total_shock_pore);
  _temperature_values_react_pore = MISTnetXUtils::formData(csv_total_react_pore);
  _time_values_pore = MISTnetXUtils::formData(csv_total_times_pore);
}

void 
ADComputeIntPValRDXMISTERnetInteger::initQpStatefulProperties()
{
  _v_flag[_qp] = ADReal(0.0);
  _stored_shock = _temperature_mister_shock_old[_qp];
  _stored_react = _temperature_mister_react_old[_qp];
  _time_react[_qp]  = ADReal(_time_react_old[_qp]);
  _called_up[_qp] = _called_up_old[_qp];
  _rate_tracking[_qp] = 0.;
}

void
ADComputeIntPValRDXMISTERnetInteger::computeQpProperties()
{
  //store density in material property
  _density[_qp] = ADReal(_density_csv[_qp]);
  //KEEP THIS ORDER

  //ORDER 1
  //keep stateful value 1
  _v_flag[_qp] = ADReal(_v_flag_old[_qp]);
  _temperature_mister_shock[_qp] = _temperature_mister_shock_old[_qp];
  _temperature_mister_react[_qp] = _temperature_mister_react_old[_qp];
  _time_react[_qp] = ADReal(_time_react_old[_qp]);
  _called_up[_qp] = _called_up_old[_qp];

  //ORDER 2
  //activate shock heat: call when velocity is bigger than a value 1

  //build velocity and acceleration vectors
  std::vector<ADReal> v_vect(_v.size());
  std::vector<ADReal> a_vect(_a.size());

  for (unsigned int i = 0; i < _v.size(); ++i){
    v_vect[i] = (*_v[i])[_qp];
  }
  for (unsigned int j = 0; j < _a.size(); ++j){
    a_vect[j] = (*_a[j])[_qp];
  }

  //define inline for L2norm
  auto L2norm = [](const std::vector<ADReal> & vect) -> ADReal
  {
    ADReal sum = 0;
    for (int i = 0; i < vect.size(); ++i){
      sum += (vect[i] * vect[i]);
    }
    return MetaPhysicL::sqrt(sum);
  };

  auto time_equil = [this](const ADReal & up) -> ADReal
  {
    //define condition for deflagrating or quench
    if (_temperature_mister_react[_qp] > 1000){
      ADReal time_def = 8.046150413374 * MetaPhysicL::exp(-0.963962928923 * up);
      return time_def;
    }
    else{
      ADReal time_quench = 0.000082188048 * MetaPhysicL::exp(3.430175735695 * up);
      return time_quench;
    }
  };

  const ADReal v_norm = L2norm(v_vect);
  
  //use the helper function
  _us[_qp] = computeUs(v_norm, _coeffs);
  
  //declare rate for shock tracking
  _rate_tracking[_qp] = (v_norm > _thr_v) ? _us[_qp] / (3 * _h) : ADReal(0.); //this is the time it takes for the shock to travel 3 elements
  //form call condition by evaluating when v is equal to a

  //LOGIC:
  //1. Expect a to be greater than a value, around 1
  //2. When norm(v) = norm(a) we call
  //3. Call is still stateful

  bool _call_condition = false;

  //to get the old behavior, use up/us and thr_a to be smaller than a value

  if (_qp==0){
    if(_v_flag[_qp]==0.){
      if (v_norm >= _thr_v && _tracking[_qp] >= ADReal(0.99)){
        _call_condition = true;
      }
    }
  }

  if (_call_condition){ //we need V and A constraints to make sure the call happens at the actual shock velocity
    _v_flag[_qp] = 1.0; //set flag to one, call in misternet material as condition for ComputeQpProperties
    //get temperatures
    const auto micro_id = MicrostructureID::get(*_fe_problem.mesh().elemPtr(_current_elem->id()), _micro_id_index);
    if (micro_id > static_cast<dof_id_type>(std::numeric_limits<int>::max()))
      mooseError("Microstructure ID exceeds predictor index range on element ", _current_elem->id());
    const int id_call = static_cast<int>(micro_id);

    //here we need to branch if we are using bulk or MicroID values

    //declare values for binder
    Real pred_shock, pred_react, pred_time;

    //define cases
    //cases for when loaded_micro = false
    bool is_pore = false;
    bool is_bulk = false;
    bool is_binder = false;

    //standard distribution case
    is_pore = (id_call >= _range_pore[0] && id_call <= _range_pore[1]);
    is_bulk = (id_call == _bulk_MicroID);
    is_binder = (!is_pore && !is_bulk);
    
    //define call velocity explicitly
    const Real call_up = std::clamp(v_norm.value(), (0.0), (4.89));

    //retrieve data based on grain or binder
    if (is_binder){ //this is the usual loop
      //assign hand coded values as placeholders
      //call the pair of values only once
      const std::pair<Real, Real> temps = getTemperatures(call_up, id_call, "binder");
      pred_shock = temps.first;
      pred_react = temps.second;
      if (_use_tabular_time){
        pred_time  = getTimes(call_up, id_call, "binder");
      }
    }
    else if (is_pore){ //this is the loop for grains (pore + bulk)
      //manually clamp the id
      int id_call_pore = id_call;
      if (id_call >= _range_pore.back()){
        id_call_pore = _range_pore.back();
      }
      if (id_call <= _range_pore.front()){
        id_call_pore = _range_pore.front();
      }
      //call temperature only once and store both values
      const std::pair<Real, Real> temps_pore = getTemperatures(call_up, id_call_pore, "pore");
      
      pred_shock = temps_pore.first;
      pred_react = temps_pore.second;
      pred_time  = getTimes(call_up, id_call_pore, "pore");
    }
    else{
      //make consistent here too
      const std::pair<Real, Real> temps_bulk = getTemperatures(call_up, id_call, "bulk");
      pred_shock = temps_bulk.first;
      pred_react = temps_bulk.second;

      if (_use_tabular_time){
        pred_time  = getTimes(call_up, id_call, "bulk");
      }
      //
    }
  
    //store in material property
    _temperature_mister_shock[_qp] = pred_shock;
    _temperature_mister_react[_qp] = pred_react;

    if (_use_tabular_time){
      _time_react[_qp] = pred_time;
    }else if (_use_distributions){
      _time_react[_qp] = getDistributionTime(call_up, _temperature_mister_react[_qp]);
      _time_react[_qp] = max(_dt, _time_react[_qp]);
    }else{
      _time_react[_qp] = time_equil(ADReal(call_up));
      _time_react[_qp] = max(_dt, min(2.0, _time_react[_qp]));
    }

    ///scale tau
    _time_react[_qp] *= _tau_react_scaling;

    //get the temeprature at the initial qp
    _stored_shock = pred_shock;
    _stored_react = pred_react;

    if (_use_tabular_time){
      _stored_time  = pred_time;
    }
    
    _called_up[_qp] = v_norm;
  }

  //ORDER 3
  if (_qp > 0.){
    _v_flag[_qp] = _v_flag[0];
    _temperature_mister_shock[_qp] = _temperature_mister_shock[0];
    _temperature_mister_react[_qp] = _temperature_mister_react[0];
    _time_react[_qp] = _time_react[0];
    _called_up[_qp] = _called_up[0];
  }  
}

//interpolate between values
//use pointers to avoid memory issues
//make interpolation term wise 
Real
ADComputeIntPValRDXMISTERnetInteger::interpolation(const std::vector<Real> & A, const std::vector<Real> & B, const Real t, const unsigned int index){
  return MISTnetXUtils::interpolation(A, B, t, index, *_current_elem, _micro_id_index);
}

// Keep the interval state used by getTimes while delegating temperature lookup.
std::pair<Real, Real>
ADComputeIntPValRDXMISTERnetInteger::getTemperatures(const Real up,
                                                  const int id,
                                                  const std::string phase)
{
  _interval = MISTnetXUtils::computeInterval(up, _up_values);
  _interval_pore = MISTnetXUtils::computeInterval(up, _up_values_pore);
  const auto & velocities = phase == "pore" ? _up_values_pore : _up_values;
  const auto interval = static_cast<unsigned int>(phase == "pore" ? _interval_pore : _interval);
  _ratio = (up - velocities[interval]) / (velocities[interval + 1] - velocities[interval]);

  return MISTnetXUtils::getTemperatures(up,
                                      id,
                                      phase,
                                      _up_values,
                                      _up_values_pore,
                                      _temperature_values_shock,
                                      _temperature_values_react,
                                      _temperature_values_shock_pore,
                                      _temperature_values_react_pore,
                                      std::make_pair(static_cast<Real>(_range_pore.front()),
                                                     static_cast<Real>(_range_pore.back())),
                                      _current_elem,
                                      _micro_id_index,
                                      _bulk_sensitivity);
}

Real
ADComputeIntPValRDXMISTERnetInteger::getTimes(const Real up, const int id, const std::string phase)
{
  return MISTnetXUtils::getTimes(up,
                               id,
                               phase,
                               _up_values,
                               _up_values_pore,
                               _time_values,
                               _time_values_pore,
                               std::make_pair(static_cast<Real>(_range_pore.front()),
                                              static_cast<Real>(_range_pore.back())),
                               _current_elem,
                               _micro_id_index,
                               _bulk_sensitivity);
}

//function for retrieving distribution data
Real
ADComputeIntPValRDXMISTERnetInteger::getDistributionTime(const Real up, const Real predicted_temp)
{
  const Real scaled_up = 10. * up;
  const int lower_up = static_cast<int>(std::floor(scaled_up));
  const int upper_up = static_cast<int>(std::ceil(scaled_up));

  const std::string appendix =
      predicted_temp > 1000. ? "_reacted" : "_unreacted";

  const DistributionName lower_name = std::to_string(lower_up) + appendix;
  const Distribution & lower_distribution = getDistributionByName(lower_name);

  const Real seed = MooseRandom::rand();
  const Real lower_time = lower_distribution.quantile(seed);

  // Exactly on a velocity grid point: no interpolation needed.
  if (lower_up == upper_up)
    return lower_time;

  const DistributionName upper_name = std::to_string(upper_up) + appendix;
  const Distribution & upper_distribution = getDistributionByName(upper_name);
  const Real upper_time = upper_distribution.quantile(seed);

  const Real weight = (scaled_up - lower_up) / (upper_up - lower_up);
  return lower_time + weight * (upper_time - lower_time);
}

//we can define an explicit function that computes the interval of u_p where we are

Real
ADComputeIntPValRDXMISTERnetInteger::computeInterval(const Real up, const std::vector<Real> & up_values){
  return MISTnetXUtils::computeInterval(up, up_values);
}

//define a function that forms the vectors neeeded for interpolation
//this takes vector of vectors and returns the member vector

// std::vector<std::vector<Real>>
// ADComputeIntPValRDXMISTERnetInteger::formData(const std::vector<std::vector<Real>> & csv){
//   return MISTnetXUtils::formData(csv);
// }

//also generate a function to form velocity vectors for intepolation
std::vector<Real>
ADComputeIntPValRDXMISTERnetInteger::formVelocityVector(const std::vector<std::vector<Real>> & csv){
  //form output
  std::vector<Real> velocity;
  for (auto & row : csv){
    //no need to check for size here
    velocity.emplace_back(row[0]);
  }
  return velocity;
}

//define helper function to evaluate us-up relation
ADReal
ADComputeIntPValRDXMISTERnetInteger::computeUs(const ADReal & up, const std::vector<Real> & coeffs){
  //form the polynomial from the coefficients
  ADReal us = ADReal(0.);
  for (unsigned int i = 0; i < coeffs.size(); ++i){
    us += coeffs[i] * MetaPhysicL::pow(up, static_cast<int>(coeffs.size() - 1 - i));
  }
  return us;
}