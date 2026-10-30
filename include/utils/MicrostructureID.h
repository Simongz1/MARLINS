#pragma once

#include "MooseError.h"
#include "MooseTypes.h"
#include "libmesh/elem.h"
#include <vector>

/** Integer labels belong to the original coarse regions, not projected FE fields. */
namespace MicrostructureID
{
inline const libMesh::Elem &
region(const libMesh::Elem & elem)
{
  const libMesh::Elem * original = &elem;
  while (original->parent())
    original = original->parent();
  return *original;
}

inline dof_id_type
get(const libMesh::Elem & elem, unsigned int index)
{
  const auto & original = region(elem);
  const auto id = original.get_extra_integer(index);
  if (id == libMesh::DofObject::invalid_id)
    mooseError("Missing integer microstructure ID on original element ", original.id(),
               " while evaluating element ", elem.id(), ". Use the integer initializer and mesh label.");
  return id;
}

inline Real
tableValue(const std::vector<Real> & values,
           dof_id_type index,
           const libMesh::Elem & elem,
           dof_id_type micro_id,
           Real time,
           const std::string & table)
{
  if (index >= values.size())
    mooseError("Integer microstructure lookup failed: table=", table, ", time=", time,
               ", element=", elem.id(), ", original_element=", region(elem).id(),
               ", microstructure_id=", micro_id, ", index=", index,
               ", table_size=", values.size());
  return values[index];
}
}
