module COVID_data_tool

using HTTP, DataFrames, CSV, JSON

include("diccionarios_claves.jl")

function getJSSIn(clave_indicador:: String, clave_municipio:: String, estado:: String, clave_estado:: String)
  l = count(i -> (i == ','), clave_municipio)
  ak = split(clave_municipio[1:end-1], ",")
  j = (length(ak) + 1)
  Ax = Array{Any, 2}(missing, length(ak), 2)

  for i in 1:length(ak)
    Ap = getJSS(clave_indicador, string(ak[i]));
    At = get(Ap[1], "OBSERVATIONS", "Not founded");
    Ar = getVG(At, clave_estado);
    Ax[i] = Ar[1]
    Ax[j] = Ar[2]
    j += 1
  end

  return Ax
end

function getJSS(clave_indicador:: String, clave_municipio:: String)
  token = "2e01d681-33e2-9414-67d3-5580000f46b4";
  #token = "60f078ff-60e6-4906-a4da-0dec849de700";
  #token = "d4f8f24b-8030-4864-b5e6-858a83ab5605";
  jurl = "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/$(clave_indicador)/es/$(clave_municipio)/true/BISE/2.0/$(token)?type=json";
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

function get_clave_municipio(municipio:: String, clave_estado:: String)
  clave_municipio = ""

  for k in keys(diccionario_municipios[parse(Int64, clave_estado)])
    if k == municipio
      clave_municipio = "0700" * clave_estado * get(diccionario_municipios[parse(Int64, clave_estado)], k, "Not founded") * ","
    end
  end

  return clave_municipio
end

function getDF(data:: Array{Any,2})
  return DataFrame(data, :auto)
end

function Ct_DocCSV(nombre_archivo:: String, tabla_datos:: DataFrame)
  CSV.write(nombre_archivo, tabla_datos)
  return nombre_archivo * " creado"
end

function indicadores_disponibles()
  for key in keys(diccionario_indicadores)
    println(key)
  end
end

function datos_indicador(indicador:: String, estado:: String)
  clave_estado = get_clave_estado(estado);
  clave_indicador = get_clave_indicador(indicador);
  claves_municipios = ""

  for k in keys(diccionario_municipios[parse(Int64, clave_estado)])
    claves_municipios *= get_clave_municipio(k, clave_estado)
  end

  Ardic = getJSSIn(clave_indicador, claves_municipios, estado, clave_estado);

  Ardic = getDF(Ardic)
  rename!(Ardic, :x1 => :Municipio)
  rename!(Ardic, :x2 => indicador)

  nombre_archivo = "datos_" * indicador * "_" * estado * ".csv"
  Ct_DocCSV(nombre_archivo, Ardic)
end

function datos_municipio(indicadores, estado::String, municipio::String)
  clave_estado = get_clave_estado(estado)
  clave_municipio = get_clave_municipio(municipio, clave_estado)
  claves_indicadores = []
  tablas_datos = []
  arreglo_df_datos = []

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
end


#Codigo para prueba
#=
#Muestra los indicadores disponibles
COVID_data_tool.indicadores_disponibles()

#Necesita de entrada el estado y el indicador a consultar
indicador = "Edad mediana"
COVID_data_tool.datos_indicador("Edad mediana", "Colima")

#Necesita de entrada el estado, municipio de ese estado y el arreglo de indicadores con los indicadores que se necesitan
indicadores = ["Defunciones Generales", "Edad mediana", "Nacimientos", "Población total", "Población de 5 años y más hablante de lengua indígena"]
COVID_data_tool.datos_municipio(indicadores, "Aguascalientes", "Aguascalientes")
=#

export datos_municipio
export datos_indicador

end #module
