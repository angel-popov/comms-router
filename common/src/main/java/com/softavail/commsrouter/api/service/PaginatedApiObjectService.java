package com.softavail.commsrouter.api.service;

import com.softavail.commsrouter.api.dto.misc.PaginatedList;
import com.softavail.commsrouter.api.dto.misc.PagingRequest;
import com.softavail.commsrouter.api.exception.CommsRouterException;
import com.softavail.commsrouter.api.interfaces.PaginatedService;
import com.softavail.commsrouter.domain.dto.mappers.EntityMapper;
import com.softavail.commsrouter.jpa.GenericRepository;
import com.softavail.commsrouter.jpa.JpaTransactionManager;

import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;
import java.util.List;
import javax.validation.ValidationException;

/**
 * Created by @author mapuo on 10.10.17.
 */
public class PaginatedApiObjectService<DTOENTITYT, ENTITYT>
    extends CoreApiObjectService<DTOENTITYT, ENTITYT>
    implements PaginatedService<DTOENTITYT> {

  private final Class<ENTITYT> entityClass;

  @SuppressWarnings("unchecked")
  public PaginatedApiObjectService(JpaTransactionManager transactionManager,
      GenericRepository<ENTITYT> repository, EntityMapper<DTOENTITYT, ENTITYT> entityMapper) {
    super(transactionManager, repository, entityMapper);

    Type tp = getClass().getGenericSuperclass();
    ParameterizedType pt = (ParameterizedType) tp;
    this.entityClass = (Class<ENTITYT>) (pt.getActualTypeArguments()[1]);
  }

  @Override
  @SuppressWarnings("unchecked")
  public PaginatedList<DTOENTITYT> list(PagingRequest request)
      throws CommsRouterException {

    return transactionManager.execute((em) -> {

      String simpleName = entityClass.getSimpleName();

      String countString = "SELECT COUNT(e.id) FROM " + simpleName + " e ";
      long totalCount = (long) em.createQuery(countString).getSingleResult();

      int startPosition = (request.getPage() * request.getPerPage()) - request.getPerPage();

      if (totalCount > 0 && totalCount <= startPosition) {
        throw new ValidationException("{resource.list.max.page.number}");
      }

      String qlString = "SELECT e FROM " + simpleName + " e";
      List<ENTITYT> jpaResult = em.createQuery(qlString)
          .setFirstResult(startPosition)
          .setMaxResults(request.getPerPage())
          .getResultList();

      return new PaginatedList<>(request, entityMapper.toDto(jpaResult), totalCount);
    });
  }

}
