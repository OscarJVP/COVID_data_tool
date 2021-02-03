using CSV,DataFrames
export COVID_data_tool
#COVID_data_tool.diccionario_indicadores
#=arreglo_dif=[]
ind=[]
for k in keys(COVID_data_tool.diccionario_estados)
    push!(ind,k)
end
ind
=#
#=
for k in ind
    @show k
    COVID_data_tool.datos_indicador("Porcentaje de hombres",k)
end
=#

ind = ["Coahuila de Zaragoza","Guerrero","Hidalgo","Nayarit","Querétaro","Quintana Roo"]

for k in ind
    @show k
    COVID_data_tool.datos_indicador("Porcentaje de mujeres",k)
    #push!(arreglo_dif, k)
end

#ind=setdiff(ind,arreglo_dif)
