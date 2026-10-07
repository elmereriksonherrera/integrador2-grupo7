package pe.utp.rentamax.repository;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import pe.utp.rentamax.model.Equipo;

import java.util.List;

public interface EquipoRepository extends JpaRepository<Equipo, Integer> {
    boolean existsByCodigo(String codigo);
    boolean existsByCodigoAndIdNot(String codigo, Integer id);
    // @EntityGraph trae la categoria con un JOIN en la misma consulta: evita el problema N+1
    // (1 consulta para los equipos + 1 por cada categoria distinta).
    @EntityGraph(attributePaths = "categoria")
    List<Equipo> findByEstadoOrderByCodigo(String estado);

    @EntityGraph(attributePaths = "categoria")
    List<Equipo> findAllByOrderByCodigo();
}
