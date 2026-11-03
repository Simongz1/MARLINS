#include "FVEulerianMISTnetEvents.h"
#include "MISTnetXUtils.h"
#include "MicrostructureID.h"
#include "NonlinearSystem.h"
#include "MooseMesh.h"
#include "libmesh/mesh_tools.h"
#include "libmesh/point_locator_base.h"
#include <algorithm>
#include <cmath>
#include <map>

registerMooseObject("mlApp",FVEulerianMISTnetEvents);
InputParameters
FVEulerianMISTnetEvents::validParams()
{
  auto p=GeneralUserObject::validParams();
  p.addClassDescription("Accepted-step Eulerian MISTnetX activation, with transported coordinates and conditional event histories.");
  p.addRequiredParam<std::string>("csv_directory","Original MISTnetX CSV directory");
  p.addParam<Real>("thr_v",.5,"Activation speed in um/ns");
  p.addParam<Real>("tau_react_scaling",1,"Multiplier on deterministic FE time fit");
  p.set<ExecFlagEnum>("execute_on")={EXEC_TIMESTEP_END};
  p.set<bool>("force_preaux")=true;
  return p;
}
FVEulerianMISTnetEvents::FVEulerianMISTnetEvents(const InputParameters & p)
 : GeneralUserObject(p),_id_index(_fe_problem.mesh().getMesh().get_elem_integer_index("legacy_prediction_id")),
 _threshold(getParam<Real>("thr_v")),
 _tau_scale(getParam<Real>("tau_react_scaling"))
{
  const auto dir=getParam<std::string>("csv_directory")+"/";
  const auto a=MISTnetXUtils::readCSV(dir+"shock_new.csv"),b=MISTnetXUtils::readCSV(dir+"shock_pore.csv");
  for(const auto & row:a) _velocities.push_back(row.at(0));
  for(const auto & row:b) _pore_velocities.push_back(row.at(0));
  _shock=MISTnetXUtils::formData(a);_pore_shock=MISTnetXUtils::formData(b);
  _react=MISTnetXUtils::formData(MISTnetXUtils::readCSV(dir+"react_new.csv"));
  _pore_react=MISTnetXUtils::formData(MISTnetXUtils::readCSV(dir+"react_pore.csv"));
  if(_velocities.size()<2 || _pore_velocities.size()<2 || _velocities.back()<=4.89 || _pore_velocities.back()<=4.89)
    mooseError("MISTnetX tables must bracket the upper lookup speed 4.89.");
}
void
FVEulerianMISTnetEvents::execute()
{
  if(_t_step==0) return;
  auto & sys=_fe_problem.getNonlinearSystem(0);
  auto & solution=sys.solution();
  std::map<std::string,unsigned int> vars;
  for(const auto n:{"rho","mx","my","rho_tracking","rho_active","rho_active_phi","rho_phi","rho_Tshock","rho_Treact","rho_tau","rho_up","rho_X","rho_Y","rho_inlet"})
    vars[n]=sys.getVariable(0,n).number();
  auto locator=_fe_problem.mesh().getPointLocator();
  const auto bounds=MeshTools::create_bounding_box(_fe_problem.mesh().getMesh());
  std::vector<std::pair<dof_id_type,Real>> updates;
  for(const auto * elem:_fe_problem.mesh().getMesh().active_local_element_ptr_range())
  {
    const auto dof=[&](const std::string & name){return elem->dof_number(sys.number(),vars.at(name),0);};
    const auto value=[&](const std::string & name){return solution(dof(name));};
    const Real rho=value("rho");
    if(rho<=0) mooseError("Nonpositive density at accepted MISTnetX event.");
    const Real active=std::clamp(value("rho_active"),0.,rho);
    if(active>=rho*(1-1e-10)) continue;
    const Real speed=std::hypot(value("mx"),value("my"))/rho;
    if(speed<_threshold || value("rho_tracking")/rho<.99) continue;
    Point X(value("rho_X")/rho,value("rho_Y")/rho,0);
    for(unsigned int i=0;i<2;++i)
    {
      const Real eps=1e-10*(bounds.max()(i)-bounds.min()(i));
      X(i)=std::clamp(X(i),bounds.min()(i)+eps,bounds.max()(i)-eps);
    }
    // Query the immutable INITIAL spatial ID map at the transported material
    // coordinate. No arithmetic or rounding of microstructure IDs is used.
    const auto * material=(*locator)(X);
    if(!material) mooseError("Unable to locate transported material coordinate ",X);
    const auto id=value("rho_inlet")/rho>.5 ? dof_id_type(99):MicrostructureID::get(*material,_id_index);
    const std::string phase=id>=101 && id<=103?"pore":(id==99?"bulk":"binder");
    const Real up=std::clamp(speed,0.,4.89);
    const auto targets=MISTnetXUtils::getTemperatures(up,id,phase,_velocities,_pore_velocities,
      _shock,_react,_pore_shock,_pore_react,{101,103},material,_id_index,20);
    Real tau=targets.second>1000 ? 8.046150413374*std::exp(-.963962928923*up)
                                :.000082188048*std::exp(3.430175735695*up);
    tau=_tau_scale*std::max(_dt,std::min(2.,tau));
    const Real newly_active=rho-active;
    updates.emplace_back(dof("rho_active"),rho);
    updates.emplace_back(dof("rho_active_phi"),value("rho_active_phi")+newly_active*value("rho_phi")/rho);
    for(const auto & entry:std::vector<std::pair<std::string,Real>>{{"rho_Tshock",targets.first},{"rho_Treact",targets.second},{"rho_tau",tau},{"rho_up",speed}})
      updates.emplace_back(dof(entry.first),value(entry.first)+newly_active*entry.second);
    // New material enters with zero clocks. Existing clock moments are retained;
    // division by the increased active mass gives the conditional mixed age.
  }
  for(const auto & update:updates) solution.set(update.first,update.second);
  solution.close();sys.update();
}
