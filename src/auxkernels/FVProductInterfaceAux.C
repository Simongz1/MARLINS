#include "FVProductInterfaceAux.h"
#include "MooseVariableFV.h"
#include "libmesh/remote_elem.h"
#include <cmath>

registerMooseObject("mlApp", FVProductInterfaceAux);

InputParameters
FVProductInterfaceAux::validParams()
{
  auto p = AuxKernel::validParams();
  p.addClassDescription("Marks both cells beside a Y3 jump if either cell's surrogate reaction window has finished.");
  p.addRequiredParam<MooseFunctorName>("products", "Cell-centered Y3 field");
  p.addRequiredParam<MooseFunctorName>("reaction_clock", "Elapsed surrogate reaction time");
  p.addRequiredParam<MooseFunctorName>("reaction_duration", "Predicted surrogate reaction duration");
  p.addRangeCheckedParam<Real>("jump_threshold", .1, "jump_threshold>0",
                              "Minimum absolute Y3 difference across a face; a dimensionless h*gradient criterion");
  p.addRelationshipManager("ElementSideNeighborLayers",
      Moose::RelationshipManagerType::GEOMETRIC | Moose::RelationshipManagerType::ALGEBRAIC,
      [](const InputParameters &, InputParameters & rm) { rm.set<unsigned short>("layers") = 2; });
  return p;
}

FVProductInterfaceAux::FVProductInterfaceAux(const InputParameters & p)
  : AuxKernel(p), _products(getFunctor<Real>("products")),
    _clock(getFunctor<Real>("reaction_clock")), _duration(getFunctor<Real>("reaction_duration")),
    _jump_threshold(getParam<Real>("jump_threshold"))
{
  if (!dynamic_cast<MooseVariableFV<Real> *>(&_var))
    paramError("variable", "Use a cell-centered MooseVariableFVReal flag variable.");
}

Real
FVProductInterfaceAux::computeValue()
{
  const auto state = determineState();
  const auto cell = makeElemArg(_current_elem);
  const Real products = _products(cell, state);
  const bool finished = _clock(cell, state) > _duration(cell, state);

  for (unsigned int side = 0; side < _current_elem->n_sides(); ++side)
  {
    const auto * neighbor = _current_elem->neighbor_ptr(side);
    if (!neighbor)
      continue;
    if (neighbor == libMesh::remote_elem)
      mooseError("FVProductInterfaceAux requires ghosted face neighbors.");

    std::vector<const libMesh::Elem *> active_neighbors;
    if (neighbor->active())
      active_neighbors.push_back(neighbor);
    else
      // A coarse cell can border several active children after AMR.
      neighbor->active_family_tree_by_neighbor(active_neighbors, _current_elem);

    for (const auto * active : active_neighbors)
    {
      if (active == libMesh::remote_elem)
        mooseError("FVProductInterfaceAux requires ghosted active face neighbors.");
      const auto other = makeElemArg(active);
      const bool other_finished = _clock(other, state) > _duration(other, state);
      if ((finished || other_finished) &&
          std::abs(products - _products(other, state)) >= _jump_threshold)
        return 1;
    }
  }
  return 0;
}
