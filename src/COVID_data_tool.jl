module COVID_data_tool

using HTTP,DataFrames,CSV,JSON

include("diccionario_claves.jl")

function getJSSIn(indicator:: String, geo_a:: String, estado:: String,ind_Es:: String)
  token="2e01d681-33e2-9414-67d3-5580000f46b4";
  l=count(i->(i==','), geo_a)
  ak=split(geo_a[1:end-1],",")
  j= (length(ak)+1)
  Ax=Array{Any,2}(missing,length(ak),2)

  for i in 1:length(ak)
    Ap=getJSS(indicator,string(ak[i]),token);
    At=get(Ap[1],"OBSERVATIONS","Not founded");
    Ar=getVG(At,ind_Es);
    Ax[i]=Ar[1]
    Ax[j]=Ar[2]
    j+=1
  end

  return Ax
end

function getJSS(indicator:: String, geo_a:: String, token:: String)
  jurl="https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/$(indicator)/es/$(geo_a)/true/BISE/2.0/$(token)?type=json";
  # @show jurl
  resp = HTTP.get(jurl);
  str = String(resp.body);
  jobj = JSON.Parser.parse(str);

  return ser=jobj["Series"]
end

function getVG(Arob2:: Array{Any,1}, in_E:: String)
  j=length(Arob2)+1
  Arax= Array{Any,2}(undef,length(Arob2),2)

  for i in 1:length(Arob2)
    for k in keys(ind_mun_est[parse(Int64,in_E)])
      if get(Arob2[i],"COBER_GEO","Not founded") == ("0700"*in_E*get(ind_mun_est[parse(Int64,in_E)],k,"Not founded"))
        Arax[i]=k
        break
      else
        Arax[i]="missing"
      end
    end
    Arax[j]=parse(Float64,get(Arob2[i],"OBS_VALUE","Not founded"))
    j+=1
  end

  return Arax
end

function setIT(ind_tabla_nombre:: String)
  indT=""
  for k in keys(ind_tabla)
    if k == ind_tabla_nombre
      indT=get(ind_tabla,k,"Not founded")
      break;
    end
  end

  return indT
end

function get_ind(Nombre_estado:: String)
  for k in keys(ind_est)
    if k == Nombre_estado
      return get(ind_est,k,"Estado Not founded")
    end
  end
end

function get_ind_mun(ind_E:: String)
  indicat=""
  ind=""
  for k in keys(ind_mun_est[parse(Int64,ind_E)])
    ind= "0700"*ind_E*get(ind_mun_est[parse(Int64,ind_E)],k,"Not founded")*","
    indicat*=ind
  end

  return indicat
end

function getDF(val:: Array{Any,2})
  return DataFrame(val, :auto)
end

function Ct_DocCSV(nombre_documento:: String,Con_Tables:: DataFrame)
  CSV.write(nombre_documento,Con_Tables)
  return nombre_documento*" creado"
end

function datos_indicador(indicador:: String, estado:: String)
  clave_estado=get_ind(estado);
  claves_municipios=get_ind_mun(clave_estado);
  clave_indicador=setIT(indicador);

  Ardic=getJSSIn(clave_indicador,claves_municipios,estado,clave_estado);

  Ardic=getDF(Ardic)
  rename!(Ardic,:x1=>:Municipio)
  rename!(Ardic,:x2=>:Total)

  nombre_documento="datos_"*indicador*"_"*estado*".csv"
  Ct_DocCSV(nombre_documento,Ardic)
  #=
  doc=Ct_DocCSV(nombre_documento,getDF(Ardic),header);
  CSV.read(doc,DataFrame)
  =#
end

function datos_municipio(estado::String, municipio::String, indicadores)
  ind_E=get_ind(estado)
  ind=""
  claves_indicadores=[]
  tablas_datos=[]
  arreglo_df_datos=[]

  for k in keys(ind_mun_est[parse(Int64,ind_E)])
    if k == municipio
      ind= "0700"*ind_E*get(ind_mun_est[parse(Int64,ind_E)],k,"Not founded")*","
    end
  end

  for indicador in indicadores
    push!(claves_indicadores, setIT(indicador))
  end

  for clave in claves_indicadores
    push!(tablas_datos,getJSSIn(clave,ind,estado,ind_E))
  end

  for i in 1:length(indicadores)
    aux=DataFrame(tablas_datos[i])
    rename!(aux,:x1=>:Municipio)
    rename!(aux,:x2=>indicadores[i])
    push!(arreglo_df_datos,aux)
  end

  df=DataFrame(Municipio=municipio)

  for i in 1:length(indicadores)
    df=innerjoin(df,arreglo_df_datos[i],on=:Municipio)
  end

  nombre_documento="datos_"*estado*"_"*municipio*".csv"
  Ct_DocCSV(nombre_documento,df)
  #=
  CSV.write(Name_DocF,df)
  CSV.read(doc,DataFrame)
  =#
end

#=
#Necesita de entrada el estado y el indicador a consultar
indicador="Edad mediana"
datos_indicador("Edad mediana", "Colima")

#Necesita de entrada el estado, municipio de ese estado y el arreglo de indicadores con los indicadores que se necesitan
indicadores=["Defunciones Generales","Edad mediana","Nacimientos","Población total","Población de 5 años y más hablante de lengua indígena"]
datos_municipio("Aguascalientes", "Aguascalientes", indicadores)
=#

export datos_municipio
export datos_indicador

end #module
