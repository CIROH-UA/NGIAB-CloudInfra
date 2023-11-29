################################################################################################################
################################################################################################################
##### Penultimate stage for image
FROM awiciroh/ngen as rocky_build_staging

ARG DATASET_DIRECTORIES

#RUN cd ./ngen && mkdir ${WORKDIR}/bin && cp cmake_build/ngen ${WORKDIR}/bin && cp -r data ${WORKDIR}/data \
#    && cd $WORKDIR && rm -rf ngen boost


# Remove the boost headers now that ngen is compiled; also update path and make sure dataset directory is there
RUN rm -rf ${BOOST_ROOT} && echo "export PATH=${PATH}" >> /etc/profile \
    && mkdir -p /dmod/datasets && chown root /dmod/datasets \
    && mkdir -p /dmod/datasets/static && chown root /dmod/datasets/static \
    && mkdir -p /dmod/shared_libs && chown root /dmod/shared_libs \
    && mkdir -p /dmod/bin && chown root /dmod/bin 

# Change permissions for entrypoint and make sure dataset volume mount parent directories exists
# chmod +x ${WORKDIR}/entrypoint.sh \
RUN for d in ${DATASET_DIRECTORIES}; do mkdir -p /dmod/datasets/${d}; done \
    && for d in iso_c_fortran_bmi noah-owp-modular topmodel cfe sloth 'evapotranspiration/evapotranspiration'; do \
        if [ -d ${WORKDIR}/ngen/extern/${d}/cmake_build ]; then \
            cp -a ${WORKDIR}/ngen/extern/${d}/cmake_build/*.so* /dmod/shared_libs/.; \
        fi; \
    done \
    && find ${WORKDIR}/ngen/extern/noah-owp-modular -type f -iname "*.TBL" -exec cp '{}' /dmod/datasets/static  \; \
    && ( cp -a ${WORKDIR}/ngen/cmake_build_parallel/ngen /dmod/bin/ngen-parallel || true ) \
    && ( cp -a ${WORKDIR}/ngen/cmake_build_serial/ngen /dmod/bin/ngen-serial || true ) \
    && ( cp -a ${WORKDIR}/ngen/cmake_build_parallel/partitionGenerator /dmod/bin/partitionGenerator || true ) \
    && pushd /dmod/bin \
    && ( ( stat ngen-parallel && ln -s ngen-parallel ngen ) || ( stat ngen-serial && ln -s ngen-serial ngen ) ) \
    && popd 

WORKDIR ${WORKDIR}
ENV PATH=${WORKDIR}:$PATH


################################################################################################################
##### Final stage for image
FROM rockylinux:9.1-minimal

########################################Copy over the NGEN artifacts############################################
COPY --chown=root --from=rocky_build_staging /dmod/ /dmod/
COPY --chown=root --from=rocky_build_staging /usr/ /usr/
########################################Relink the files########################################################
RUN echo "/dmod/shared_libs/" >> /etc/ld.so.conf.d/ngen.conf && ldconfig -v

COPY   HelloNGEN.sh /ngen/HelloNGEN.sh
RUN chown -R root /dmod /ngen /root
RUN chmod a+x /dmod/bin/* /ngen/HelloNGEN.sh /root
RUN rm -rf tmp var opt 
WORKDIR /ngen

ENTRYPOINT ["./HelloNGEN.sh"]
CMD [""]
