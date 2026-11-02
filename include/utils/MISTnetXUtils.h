#pragma once

#include "MooseError.h"
#include "MooseTypes.h"
#include "libmesh/elem.h"
#include <fstream>
#include <sstream>
#include "FEProblem.h"
#include "MicrostructureID.h"
#include <cmath>

namespace MISTnetXUtils
{
  //function to read csv data, callable from other parts of the code
  inline std::vector<std::vector<Real>>
  readCSV(const std::string csv_file_name){
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

  inline Real interpolation(const std::vector<Real> & A, 
                            const std::vector<Real> & B, 
                            const Real t, 
                            const unsigned int index,
                            const libMesh::Elem & current_element,
                            const unsigned int micro_id_index){
    //get microstructure ID
    const auto id = MicrostructureID::get(current_element, micro_id_index);

    return (1.0 - t) * MicrostructureID::tableValue(A, index, current_element, id, "predictor lower row") +
           t * MicrostructureID::tableValue(B, index, current_element, id, "predictor upper row");
  }

  inline Real
  computeInterval(const Real up, const std::vector<Real> & up_values){
    //define value to return
    //dereference the pointer for the vector of up values
    const std::vector<Real> & up_vals = up_values;

    //iterate
    Real interval_number = 0.;
    for (unsigned int i = 1; i < up_vals.size(); ++i){
      //find the i values where up_call is between the lower and the upper bounds of the interval
      if (up_vals[i] > up){
        interval_number = i - 1;
        break;
      }
    }
    return interval_number;
  }

  inline std::vector<std::vector<Real>> formData(const std::vector<std::vector<Real>> & csv){

    //form output
    std::vector<std::vector<Real>> data;

    //iterate
    for (auto &row : csv){
      if (row.size() < 2){
        mooseError("need bigger CSV");
      }
    
      data.emplace_back(row.begin() + 1, row.end());
    }
    return data;
  }

  //define function to read temperatures
  inline std::pair<Real, Real>
  getTemperatures(const Real up,
                  const int id, 
                  const std::string phase, 
                  const std::vector<Real> & up_values,
                  const std::vector<Real> & up_values_pore,
                  const std::vector<std::vector<Real>> & temperature_values_shock,
                  const std::vector<std::vector<Real>> & temperature_values_react,
                  const std::vector<std::vector<Real>> & temperature_values_shock_pore,
                  const std::vector<std::vector<Real>> & temperature_values_react_pore,
                  const std::pair<Real, Real> & range_pore,
                  const libMesh::Elem * current_element,
                  const unsigned int micro_id_index,
                  const int bulk_sensitivity){

    //forward declaration
    Real lower_bound, upper_bound, interval_number;

    //change these to null pointers
    const std::vector<Real> * lower_temps_shock = nullptr;
    const std::vector<Real> * upper_temps_shock = nullptr;
    const std::vector<Real> * lower_temps_react = nullptr;
    const std::vector<Real> * upper_temps_react = nullptr;

    //to use the same interval, call it here
    const Real _interval = computeInterval(up, up_values);
    const Real _interval_pore = computeInterval(up, up_values_pore);

    //here we need to branch based on the phase
    if (phase == "binder"){
      //direct assignment of the shock temperatures
      //dereference the pointers here to assign value
      lower_temps_shock = &temperature_values_shock[static_cast<unsigned int>(_interval)];
      upper_temps_shock = &temperature_values_shock[static_cast<unsigned int>(_interval) + 1];

      //direct assignment of the reaction temperatures
      lower_temps_react = &temperature_values_react[static_cast<unsigned int>(_interval)];
      upper_temps_react = &temperature_values_react[static_cast<unsigned int>(_interval) + 1];

      //and also assign bounds for interpolation
      lower_bound = up_values[static_cast<unsigned int>(_interval)];
      upper_bound = up_values[static_cast<unsigned int>(_interval) + 1];
    }
    else if (phase == "pore"){
      //direct assignment of shock temperatures
      lower_temps_shock = &temperature_values_shock_pore[static_cast<unsigned int>(_interval_pore)];
      upper_temps_shock = &temperature_values_shock_pore[static_cast<unsigned int>(_interval_pore) + 1];

      //direct assignment of reaction temperatures
      lower_temps_react = &temperature_values_react_pore[static_cast<unsigned int>(_interval_pore)];
      upper_temps_react = &temperature_values_react_pore[static_cast<unsigned int>(_interval_pore) + 1];

      //assign bounds
      lower_bound = up_values_pore[static_cast<unsigned int>(_interval_pore)];
      upper_bound = up_values_pore[static_cast<unsigned int>(_interval_pore) + 1];
    }
    else if (phase == "bulk"){
      //direct assignment of shock temperatures
      lower_temps_shock = &temperature_values_shock[static_cast<unsigned int>(_interval)];
      upper_temps_shock = &temperature_values_shock[static_cast<unsigned int>(_interval) + 1];

      //direct assingmnet of reaction temperatures
      lower_temps_react = &temperature_values_react[static_cast<unsigned int>(_interval)];
      upper_temps_react = &temperature_values_react[static_cast<unsigned int>(_interval) + 1];

      //assign bounds
      lower_bound = up_values[static_cast<unsigned int>(_interval)];
      upper_bound = up_values[static_cast<unsigned int>(_interval) + 1];
    }

    //this assigns the ratio
    const Real t = (up - lower_bound) / (upper_bound - lower_bound);

    Real temp_shock;
    Real temp_react;

    if (phase == "binder"){ //traditional branch
      temp_shock = interpolation(*lower_temps_shock, 
                                 *upper_temps_shock, 
                                 t, 
                                 id, 
                                 *current_element, 
                                 micro_id_index);
      temp_react = interpolation(*lower_temps_react, 
                                 *upper_temps_react, 
                                 t, 
                                 id, 
                                 *current_element,
                                 micro_id_index);
    }

    if (phase == "pore"){
      //the pore microstructures are 101, 102, 103, so we need to subtract to access the data
      int id_pore = static_cast<int>(std::round(id - range_pore.first));

      // Do not clamp IDs into a different physical microstructure; interpolation checks bounds.
      
      //now access pore data
      temp_shock = interpolation(*lower_temps_shock, 
                                 *upper_temps_shock, 
                                 t, 
                                 id_pore, 
                                 *current_element, 
                                 micro_id_index);
      temp_react = interpolation(*lower_temps_react, 
                                 *upper_temps_react, 
                                 t, 
                                 id_pore, 
                                 *current_element, 
                                 micro_id_index);
    }
    if (phase == "bulk"){
      //bulk will preserve the nanoPBX data, but will be called all at an insensitive microstructure
      const int id_bulk = bulk_sensitivity; //the most insensitive, this can be tuned until bulk data is available
      
      //now access bulk data
      temp_shock = interpolation(*lower_temps_shock, 
                                 *upper_temps_shock, 
                                 t, 
                                 id_bulk, 
                                 *current_element, 
                                 micro_id_index);
      temp_react = interpolation(*lower_temps_react, 
                                 *upper_temps_react, 
                                 t, 
                                 id_bulk, 
                                 *current_element, 
                                 micro_id_index);
    }

    //make the return type consistent
    return std::make_pair(temp_shock, temp_react);
  }

  // Use the same velocity grids and stripped CSV columns as getTemperatures.
  inline Real
  getTimes(const Real up,
           const int id,
           const std::string phase,
           const std::vector<Real> & up_values,
           const std::vector<Real> & up_values_pore,
           const std::vector<std::vector<Real>> & time_values,
           const std::vector<std::vector<Real>> & time_values_pore,
           const std::pair<Real, Real> & range_pore,
           const libMesh::Elem * current_element,
           const unsigned int micro_id_index,
           const int bulk_sensitivity)
  {
    if (phase != "binder" && phase != "pore" && phase != "bulk")
      mooseError("Unknown MISTnetX phase in getTimes: ", phase);

    const bool is_pore = phase == "pore";
    const auto & velocities = is_pore ? up_values_pore : up_values;
    const auto & times = is_pore ? time_values_pore : time_values;
    const auto interval = static_cast<unsigned int>(computeInterval(up, velocities));
    const Real ratio = (up - velocities[interval]) /
                       (velocities[interval + 1] - velocities[interval]);

    const int column = is_pore ? id - static_cast<int>(range_pore.first)
                              : (phase == "bulk" ? bulk_sensitivity : id);
    return interpolation(times[interval],
                         times[interval + 1],
                         ratio,
                         column,
                         *current_element,
                         micro_id_index);
  }

} // namespace MISTnetXUtils
