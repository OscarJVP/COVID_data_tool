include("C:\\Julia-1.4.2\\COVID_data_tool\\src\\COVID_data_tool.jl")

COVID_data_tool.diccionario_indicadores
ind=[]
for k in keys(COVID_data_tool.diccionario_indicadores)
    push!(ind,k)
end
ind
ind=setdiff(ind,["Población de 5 años y más inmigrante"])
ind=setdiff(ind,["Población de 5 años y más emigrante"])
#ind=setdiff(ind,["Población de 5 años y más hablante de lengua indígena"])
ind
COVID_data_tool.diccionario_estados
COVID_data_tool.diccionario_indicadores
#=
for k in keys(COVID_data_tool.ind_mun_est[parse(Int64,get(COVID_data_tool.ind_est,"Campeche","Not founded"))])
    @show k
    COVID_data_tool.datos_municipio("Campeche",string(k),ind)
end
=#
for k in ind
    @show k
    COVID_data_tool.datos_indicador(k,"Yucatán")
end
