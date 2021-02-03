using CSV,DataFrames
export COVID_data_tool
COVID_data_tool.ind_tabla
ind=[]
for k in keys(COVID_data_tool.ind_est)
    push!(ind,k)
end
ind
for k in ind
    @show k
    COVID_data_tool.datos_indicador("Porcentaje de hombres",k)
end

for k in ind
    @show k
    COVID_data_tool.datos_indicador("Porcentaje de mujeres",k)
end
