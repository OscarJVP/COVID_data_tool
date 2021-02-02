module COVID_data_tool

using HTTP, DataFrames, CSV, JSON

include("diccionarios_claves.jl")

function getJSSIn(clave_indicador:: String, clave_municipio:: String, estado:: String, clave_estado:: String)
  token = "2e01d681-33e2-9414-67d3-5580000f46b4";
  l = count(i -> (i == ','), clave_municipio)
  ak = split(clave_municipio[1:end-1], ",")
  j = (length(ak) + 1)
  Ax = Array{Any, 2}(missing, length(ak), 2)

  for i in 1:length(ak)
    Ap = getJSS(clave_indicador, string(ak[i]), token);
    At = get(Ap[1], "OBSERVATIONS", "Not founded");
    Ar = getVG(At, clave_estado);
    Ax[i] = Ar[1]
    Ax[j] = Ar[2]
    j += 1
  end

  return Ax
end

function getJSS(clave_indicador:: String, clave_municipio:: String, token:: String)
  jurl="https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/$(clave_indicador)/es/$(clave_municipio)/true/BISE/2.0/$(token)?type=json";
  # @show jurl
  resp = HTTP.get(jurl);
  str = String(resp.body);
  jobj = JSON.Parser.parse(str);

  return ser = jobj["Series"]
end

function getVG(Arob2:: Array{Any, 1}, clave_estado:: String)
  j = length(Arob2) + 1
  Arax = Array{Any, 2}(undef, length(Arob2), 2)

  for i in 1:length(Arob2)
    for k in keys(diccionario_municipios[parse(Int64, clave_estado)])
      if get(Arob2[i], "COBER_GEO", "Not founded") == ("0700" * clave_estado * get(diccionario_municipios[parse(Int64, clave_estado)], k, "Not founded"))
        Arax[i] = k
        break
      else
        Arax[i] = "missing"
      end
    end
    Arax[j] = parse(Float64, get(Arob2[i], "OBS_VALUE", "Not founded"))
    j += 1
  end

  return Arax
end

function get_clave_indicador(indicador:: String)
  clave_indicador = ""
  for k in keys(diccionario_indicadores)
    if k == indicador
      clave_indicador = get(diccionario_indicadores, k, "Not founded")
      break;
    end
  end

  return clave_indicador
end

function get_clave_estado(estado:: String)
  for k in keys(diccionario_estados)
    if k == estado
      return get(diccionario_estados, k, "Estado Not founded")
    end
  end
end

function get_clave_municipio(clave_estado:: String)
  claves_anidadas_municipios = ""
  clave_municipio = ""
  for k in keys(diccionario_municipios[parse(Int64, clave_estado)])
    clave_municipio = "0700" * clave_estado * get(diccionario_municipios[parse(Int64, clave_estado)], k, "Not founded") * ","
    claves_anidadas_municipios *= clave_municipio
  end

  return claves_anidadas_municipios
end

function getDF(val:: Array{Any,2})
  return DataFrame(val, :auto)
end

function Ct_DocCSV(nombre_archivo:: String, tabla_datos:: DataFrame)
  CSV.write(nombre_archivo, tabla_datos)
  return nombre_archivo * " creado"
end

function lista_indicadores_disponibles()
  for key in keys(diccionario_indicadores)
    println(key)
  end
end

function datos_indicador(indicador:: String, estado:: String)
  clave_estado = get_clave_estado(estado);
  claves_municipios = get_clave_municipio(clave_estado);
  clave_indicador = get_clave_indicador(indicador);

  Ardic = getJSSIn(clave_indicador, claves_municipios, estado, clave_estado);

  Ardic = getDF(Ardic)
  rename!(Ardic, :x1 => :Municipio)
  rename!(Ardic, :x2 => indicador)

  nombre_archivo = "datos_" * indicador * "_" * estado * ".csv"
  Ct_DocCSV(nombre_archivo, Ardic)
  #=
  doc=Ct_DocCSV(nombre_archivo,getDF(Ardic),header);
  CSV.read(doc,DataFrame)
  =#
end

function datos_municipio(indicadores, estado::String, municipio::String)
  clave_estado = get_clave_estado(estado)
  clave_municipio = ""
  claves_indicadores = []
  tablas_datos = []
  arreglo_df_datos = []

  for k in keys(diccionario_municipios[parse(Int64, clave_estado)])
    if k == municipio
      clave_municipio = "0700" * clave_estado * get(diccionario_municipios[parse(Int64, clave_estado)], k, "Not founded") * ","
    end
  end

  for indicador in indicadores
    push!(claves_indicadores, get_clave_indicador(indicador))
  end

  for clave_ind in claves_indicadores
    push!(tablas_datos, getJSSIn(clave_ind, clave_municipio, estado, clave_estado))
  end

  for i in 1:length(indicadores)
    aux = DataFrame(tablas_datos[i])
    rename!(aux, :x1 => :Municipio)
    rename!(aux, :x2 => indicadores[i])
    push!(arreglo_df_datos, aux)
  end

  df = DataFrame(Municipio = municipio)

  for i in 1:length(indicadores)
    df = innerjoin(df, arreglo_df_datos[i], on=:Municipio)
  end

  nombre_archivo = "datos_" * estado * "_" * municipio * ".csv"
  Ct_DocCSV(nombre_archivo, df)
  #=
  CSV.write(Name_DocF,df)
  CSV.read(doc,DataFrame)
  =#
end


#Codigo para prueba

#Muestra los indicadores disponibles
lista_indicadores_disponibles()

#Necesita de entrada el estado y el indicador a consultar
indicador = "Edad mediana"
datos_indicador("Edad mediana", "Colima")

#Necesita de entrada el estado, municipio de ese estado y el arreglo de indicadores con los indicadores que se necesitan
indicadores = ["Defunciones Generales", "Edad mediana", "Nacimientos", "Población total", "Población de 5 años y más hablante de lengua indígena"]
datos_municipio(indicadores, "Aguascalientes", "Aguascalientes", )


export datos_municipio
export datos_indicador

end #module
