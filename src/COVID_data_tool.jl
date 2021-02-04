module COVID_data_tool

using DataFrames, JSON, InfoZIP, ZipFile, HTTP, CSV, XLSX, ExcelFiles, Dates
include("diccionarios_claves.jl");
include("url_paths.jl");

if Sys.iswindows()
  if isdir("C:\\archivos_CSV_COVID_data_tool") == true
    println("Carpeta C:\\archivos_CSV_COVID_data_tool existe.")
  else
    mkdir("C:\\archivos_CSV_COVID_data_tool")
  end
elseif Sys.islinux()
  if isdir("/home/archivos_CSV_COVID_data_tool") == true
    println("Carpeta /home/archivos_CSV_COVID_data_tool existe.")
  else
    mkdir("/home/archivos_CSV_COVID_data_tool")
  end
end

function getJSSIn(clave_indicador:: String, clave_municipio:: String, estado:: String, clave_estado:: String)
  l = count(i -> (i == ','), clave_municipio)
  ak = split(clave_municipio[1:end-1], ",")
  j = (length(ak) + 1)
  Ax = Array{Any, 2}(missing, length(ak), 2)

  for i in 1:length(ak)
    if clave_indicador=="1005000039" && ak[i]=="070000020006" && clave_estado=="0002"
        Ar=["San Quintín","No Data"]
    elseif clave_indicador=="1002000026" && ak[i]=="070000020006" && clave_estado=="0002"
        Ar=["San Quintín","No Data"]
    elseif clave_indicador=="1005000039" && ak[i]=="070000040012" && clave_estado=="0004"
        Ar=["Seybaplaya","No Data"]
    elseif clave_indicador=="1002000026" && ak[i]=="070000040012" && clave_estado=="0004"
        Ar=["Seybaplaya","No Data"]
    else
      Ap = getJSS(clave_indicador, string(ak[i]));
      At = get(Ap[1], "OBSERVATIONS", "Not founded");
      Ar = getVG(At, clave_estado);
    end
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
  Arax = Array{Any, 2}(undef, 2, 2)
    for k in keys(diccionario_municipios[parse(Int64, clave_estado)])
      if get(Arob2[1], "COBER_GEO", "Not founded") == ("0700" * clave_estado * get(diccionario_municipios[parse(Int64, clave_estado)], k, "Not founded"))
        Arax[1] = k
        break
      else
        Arax[1] = "missing"
      end
    end
    Arax[2] = parse(Float64, get(Arob2[1], "OBS_VALUE", "Not founded"))
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
  directorio = pathCSV * nombre_archivo
  CSV.write(directorio, tabla_datos)
  return nombre_archivo * " creado"
end

function indicadores_disponibles()
  println("***Indicadores generales***")
  for key in keys(diccionario_indicadores)
    println(key)
  end
  println("***Indicadores IDH***")
  lista_ComponentesIDH()
  println("***Indicadores de Pobreza***")
  lista_IndicadoresPobreza()
  println("***Indicadores de Intensidad Migratoria***")
  println("(Para las entradas de las funciones necesita las claves, no la descripción)")
  lista_ComponentesIIM()
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

  nombre_archivo = "datos_" * indicador * "_" * estado * "_" * Dates.format(now(), "dd_u_yyyy_HH_MM_SS") * ".csv"
  Ct_DocCSV(nombre_archivo, Ardic)
end

function lista_ComponentesIDH()
  adh=XLSX.readxlsx(path*"Indice de Desarrollo Humano Municipal 2010 2015.xlsx")["IDH municipal 2015"]
  headIDH=adh["E8:L8"];
  for str in headIDH
    println(str)
  end
end

function lista_IndicadoresPobreza()
  ar=XLSX.readxlsx(path*"Concentrado, indicadores de pobreza.xlsx")["Concentrado municipal"]
  indPob= []
  for a in ar["H5:CU5"]
      if !isequal(missing,a)
          push!(indPob,a)
      end
  end
  push!(indPob,"Indicadores de pobreza")
  indPob[16]="Población con ingreso inferior a la línea de bienestar"
  for i in indPob
    println(i)
  end
end

function lista_ComponentesIIM()
  df=DataFrame(ExcelFiles.load(path*"IIM2010_BASEMUN.xls","IIM2010_BASEMUN"))
  ar=[:ENT,:NOM_ENT,:MUN,:NOM_MUN]
  select!(df,Not(ar))
  dicIIM=Dict("TOT_VIV"=>"Total de viviendas particulares habitadas","VIV_REM"=>"Porcentaje de viviendas que reciben remesas","VIV_EMIG"=>"Porcentaje de viviendas con emigrantes a EU","VIV_CIRC"=>"Porcentaje de viviendas con migrantes circulares","VIV_RET"=>"Porcentaje de viviendas con migrantes de retorno","IIM_2010"=>"Índice de intensidad migratoria 2010","IIM0a100"=>"Indice de instansidad migratoria en escala de 0 a 100","GIM_2010"=>"Grado de intensidad migratoria 2010","LUG_EDO"=>"Lugar que ocupa en el contexto estatal","LUG_NAL"=>"Lugar que ocupa en el contexto nacional")
  for i in names(df)
    println(i*" ---> "*dicIIM[i])
  end
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

  nombre_archivo = "datos_" * estado * "_" * municipio * "_" * Dates.format(now(), "dd_u_yyyy_HH_MM_SS") * ".csv"
  Ct_DocCSV(nombre_archivo, df)
end

function comp_CovInd(indicadores::Vector{String},estado::String,municipio::String)
   dfest=DataFrame(ENTIDAD_UM=parse(Int64,get(diccionario_estados,estado,"Not founded")))
   dfmun=DataFrame(MUNICIPIO_RES=parse(Int64,get(diccionario_municipios[parse(Int64,get(diccionario_estados,estado,"Not founded"))],municipio,"Not founded")))
   f=getCovData()
   f=innerjoin(f,dfest,on=:ENTIDAD_UM)
   f=innerjoin(f,dfmun,on=:MUNICIPIO_RES)
   dfind=conjunto_estado(indicadores,estado,municipio)
   dfrec=hcat(dfmun,dfest)
   dfind=hcat(dfrec,dfind)
   f=innerjoin(f,dfind,on=[:MUNICIPIO_RES,:ENTIDAD_UM])
   nombre="Covid_union_"*estado*"_"*municipio*".csv"
   Ct_DocCSV(nombre,f)
end

function dato_estado(indicador::String,estado::String)
  if indicador=="Extension territorial"
    dfaux=getExtTer(estado)
  elseif indicador=="Indicadores de pobreza"
    dfaux=getIndPobreza("All",estado)
  elseif indicador=="IDH y componentes"
    dfaux=getIDH("All",estado)
  elseif indicador=="Intesidad migratoria y componentes"
    dfaux=getIndIM("All",estado)
  elseif haskey(diccionario_indicadores,indicador)
    dfaux=getIndINEGI(estado, indicador)
  elseif indicador=="Años promedio de escolaridad"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Años esperados de escolarización"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Ingreso per cápita anual"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Tasa de mortalidad infantil"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Índice de educación"
    dfaux=getIDH(indicador,esatdo)
  elseif indicador=="Índice de salud"
    dfaux=getIDH(indicador,esatdo)
  elseif indicador=="Índice de ingreso"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="IDH"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Pobreza"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Pobreza extrema"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Pobreza moderada"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Vulnerables por carencia social"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Vulnerables por ingreso"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="No pobres y no vulnerables"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Rezago educativo"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Carencia por acceso a los servicios de salud"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Carencia por acceso a la seguridad social"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Carencia por acceso a los servicios básicos en la vivienda"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Carencia por acceso a la alimentación"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Población con al menos una carencia social"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Población con tres o más carencias sociales"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Población con ingreso inferior a la línea de bienestar"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Población con ingreso inferior a la línea de bienestar mínimo"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="TOT_VIV"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="VIV_REM"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="VIV_EMIG"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="VIV_CIRC"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="VIV_RET"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="IIM_2010"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="IIMa100"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="GIM_2010"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="LUG_EDO"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="LUG_NAL"
    dfaux=getIndIM(indicador,estado)
  end
  plu=[]
  for k in keys(diccionario_municipios[parse(Int64,get(diccionario_estados,estado,"Not founded"))])
    push!(plu,k)
  end
  dfDel=DataFrame(Municipio=plu)
  dfaux=innerjoin(dfaux,dfDel,on=:Municipio)
  nombre_doc=indicador*"_"*estado*"_"*Dates.format(now(), "dd_u_yyyy_HH_MM_SS")*".csv"
  Ct_DocCSV(nombre_doc,dfaux)
end

function conjunto_estado(indicadores::Vector{String},estado::String)
  munau=[]
  for k in keys(diccionario_municipios[parse(Int64,get(diccionario_estados,estado,"Not founded"))])
    push!(munau,k)
  end
  dfaux=DataFrame(Municipio=munau)
  for indicador in indicadores
      if indicador=="Extension territorial"
        dfaux=innerjoin(dfaux,getExtTer(estado),on=:Municipio)
        rename!(dfaux,:Total=>indicador)
      elseif indicador=="Indicadores de pobreza"
        dfaux=innerjoin(dfaux,getIndPobreza("All",estado),on=:Municipio)
      elseif indicador=="IDH y componentes"
        dfaux=innerjoin(dfaux,getIDH("All",estado),on=:Municipio)
      elseif indicador=="Intesidad migratoria y componentes"
        dfaux=innerjoin(dfaux,getIndIM("All",estado),on=:Municipio)
      elseif haskey(diccionario_indicadores,indicador)
        dfaux=innerjoin(dfaux,getIndINEGI(estado,indicador),on=:Municipio)
        for c in 1:length(names(dfaux))
           if string(names(dfaux)[c])=="Total"
              rename!(dfaux,:Total=>indicador)
           end
         end
      elseif indicador=="Años promedio de escolaridad"
          dfaux=innerjoin(dfaux,getIDH("Años promedio de escolaridad",estado),on=:Municipio)
      elseif indicador=="Años esperados de escolarización"
          dfaux=innerjoin(dfaux,getIDH("Años esperados de escolaridad",estado),on=:Municipio)
      elseif indicador=="Ingreso per cápita anual"
          dfaux=innerjoin(dfaux,getIDH("Ingreso per cápita anual",estado),on=:Municipio)
      elseif indicador=="Tasa de mortalidad infantil"
          dfaux=innerjoin(dfaux,getIDH("Tasa de mortalidad infantil",estado),on=:Municipio)
      elseif indicador=="Índice de educación"
          dfaux=innerjoin(dfaux,getIDH("Índice de educación",estado),on=:Municipio)
      elseif indicador=="Índice de salud"
          dfaux=innerjoin(dfaux,getIDH("Índice de salud",estado),on=:Municipio)
      elseif indicador=="Índice de ingreso"
          dfaux=innerjoin(dfaux,getIDH("Índice de ingreso",estado),on=:Municipio)
      elseif indicador=="IDH"
          dfaux=innerjoin(dfaux,getIDH("IDH",estado),on=:Municipio)
      elseif indicador=="Pobreza"
        dfaux=innerjoin(dfaux,getIndPobreza("Pobreza",estado),on=:Municipio)
      elseif indicador=="Pobreza extrema"
        dfaux=innerjoin(dfaux,getIndPobreza("Pobreza extrema",estado),on=:Municipio)
      elseif indicador=="Pobreza moderada"
        dfaux=innerjoin(dfaux,getIndPobreza("Pobreza moderada",estado),on=:Municipio)
      elseif indicador=="Vulnerables por carencia social"
        dfaux=innerjoin(dfaux,getIndPobreza("Vulnerables por carencia social",estado),on=:Municipio)
      elseif indicador=="Vulnerables por ingreso"
        dfaux=innerjoin(dfaux,getIndPobreza("Vulnerables por ingreso",estado),on=:Municipio)
      elseif indicador=="No pobres y no vulnerables"
        dfaux=innerjoin(dfaux,getIndPobreza("No pobres y no vulnerables",estado),on=:Municipio)
      elseif indicador=="Rezago educativo"
        dfaux=innerjoin(dfaux,getIndPobreza("Rezago educativo",estado),on=:Municipio)
      elseif indicador=="Carencia por acceso a los servicios de salud"
        dfaux=innerjoin(dfaux,getIndPobreza("Carencia por acceso a los servicios de salud",estado),on=:Municipio)
      elseif indicador=="Carencia por acceso a la seguridad social"
        dfaux=innerjoin(dfaux,getIndPobreza("Carencia por acceso a la seguridad social",estado),on=:Municipio)
      elseif indicador=="Carencia por acceso a los servicios básicos en la vivienda"
        dfaux=innerjoin(dfaux,getIndPobreza("Carencia por acceso a los servicios básicos en la vivienda",estado),on=:Municipio)
      elseif indicador=="Carencia por acceso a la alimentación"
        dfaux=innerjoin(dfaux,getIndPobreza("Carencia por acceso a la alimentación",estado),on=:Municipio)
      elseif indicador=="Población con al menos una carencia social"
        dfaux=innerjoin(dfaux,getIndPobreza("Población con al menos una carencia social",estado),on=:Municipio)
      elseif indicador=="Población con tres o más carencias sociales"
        dfaux=innerjoin(dfaux,getIndPobreza("Población con tres o más carencias sociales",estado),on=:Municipio)
      elseif indicador=="Población con ingreso inferior a la línea de bienestar"
        dfaux=innerjoin(dfaux,getIndPobreza("Población con ingreso inferior a la línea de bienestar",estado),on=:Municipio)
      elseif indicador=="Población con ingreso inferior a la línea de bienestar mínimo"
        dfaux=innerjoin(dfaux,getIndPobreza("Población con ingreso inferior a la línea de bienestar mínimo",estado),on=:Municipio)
      elseif indicador=="TOT_VIV"
        dfaux=innerjoin(dfaux,getIndIM("TOT_VIV",estado),on=:Municipio)
      elseif indicador=="VIV_REM"
        dfaux=innerjoin(dfaux,getIndIM("VIV_REM",estado),on=:Municipio)
      elseif indicador=="VIV_EMIG"
        dfaux=innerjoin(dfaux,getIndIM("VIV_EMIG",estado),on=:Municipio)
      elseif indicador=="VIV_CIRC"
        dfaux=innerjoin(dfaux,getIndIM("VIV_CIRC",estado),on=:Municipio)
      elseif indicador=="VIV_RET"
        dfaux=innerjoin(dfaux,getIndIM("VIV_RET",estado),on=:Municipio)
      elseif indicador=="IIM_2010"
        dfaux=innerjoin(dfaux,getIndIM("IIM_2010",estado),on=:Municipio)
      elseif indicador=="IIMa100"
        dfaux=innerjoin(dfaux,getIndIM("IIMa100",estado),on=:Municipio)
      elseif indicador=="GIM_2010"
        dfaux=innerjoin(dfaux,getIndIM("GIM_2010",estado),on=:Municipio)
      elseif indicador=="LUG_EDO"
        dfaux=innerjoin(dfaux,getIndIM("LUG_EDO",estado),on=:Municipio)
      elseif indicador=="LUG_NAL"
        dfaux=innerjoin(dfaux,getIndIM("LUG_NAL",estado),on=:Municipio)
      end
  end
  nombre_doc="Conjunto_de_"*estado*"_"*Dates.format(now(), "dd_u_yyyy_HH_MM_SS")*".csv"
  Ct_DocCSV(nombre_doc,dfaux)
end

function dato_estado(indicador::String,estado::String,municipio::String)
  if indicador=="Extension territorial"
    dfaux=getExtTer(estado)
  elseif indicador=="Indicadores de pobreza"
    dfaux=getIndPobreza("All",estado)
  elseif indicador=="IDH y componentes"
    dfaux=getIDH("All",estado)
  elseif indicador=="Intesidad migratoria y componentes"
    dfaux=getIndIM("All",estado)
  elseif haskey(diccionario_indicadores,indicador)
    dfaux=getIndINEGI(estado, indicador)
  elseif indicador=="Años promedio de escolaridad"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Años esperados de escolarización"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Ingreso per cápita anual"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Tasa de mortalidad infantil"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Índice de educación"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Índice de salud"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="Índice de ingreso"
    dfaux=getIDH(indicador,estado)
  elseif indicador=="IDH"
    dfaux=getIDH(indicador,estado)
    for c in 1:length(names(dfaux))
       if string(names(dfaux)[c])=="Total"
          rename!(dfaux,:Total=>indicador)
       end
     end
  elseif indicador=="Pobreza"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Pobreza extrema"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Pobreza moderada"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Vulnerables por carencia social"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Vulnerables por ingreso"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="No pobres y no vulnerables"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Rezago educativo"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Carencia por acceso a los servicios de salud"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Carencia por acceso a la seguridad social"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Carencia por acceso a los servicios básicos en la vivienda"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Carencia por acceso a la alimentación"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Población con al menos una carencia social"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Población con tres o más carencias sociales"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Población con ingreso inferior a la línea de bienestar"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="Población con ingreso inferior a la línea de bienestar mínimo"
    dfaux=getIndPobreza(indicador,estado)
  elseif indicador=="TOT_VIV"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="VIV_REM"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="VIV_EMIG"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="VIV_CIRC"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="VIV_RET"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="IIM_2010"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="IIMa100"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="GIM_2010"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="LUG_EDO"
    dfaux=getIndIM(indicador,estado)
  elseif indicador=="LUG_NAL"
    dfaux=getIndIM(indicador,estado)
  end
  plu=[]
  for k in keys(diccionario_municipios[parse(Int64,get(diccionario_estados,estado,"Not founded"))])
    push!(plu,k)
  end
  dfDel=DataFrame(Municipio=plu)
  dfaux=innerjoin(dfaux,dfDel,on=:Municipio)
  nombre_doc=indicador*"_"*estado*"_"*Dates.format(now(), "dd_u_yyyy_HH_MM_SS")*".csv"
  Ct_DocCSV(nombre_doc,dfaux)
end

function conjunto_estado(indicadores::Vector{String},estado::String,municipio::String)
  dfaux=DataFrame(Municipio=municipio)
  for indicador in indicadores
      if indicador=="Extension territorial"
        dfaux=innerjoin(dfaux,getExtTer(estado),on=:Municipio)
        rename!(dfaux,:Total=>indicador)
      elseif indicador=="Indicadores de pobreza"
        dfaux=innerjoin(dfaux,getIndPobreza("All",estado),on=:Municipio)
      elseif indicador=="IDH y componentes"
        dfaux=innerjoin(dfaux,getIDH("All",estado),on=:Municipio)
      elseif indicador=="Intensidad migratoria y componentes"
        dfaux=innerjoin(dfaux,getIndIM("All",estado),on=:Municipio)
      elseif haskey(diccionario_indicadores,indicador)
        dfaux=innerjoin(dfaux,getIndINEGI(estado,indicador),on=:Municipio)
        for c in 1:length(names(dfaux))
           if string(names(dfaux)[c])=="Total"
              rename!(dfaux,:Total=>indicador)
           end
         end
      elseif indicador=="Años promedio de escolaridad"
          dfaux=innerjoin(dfaux,getIDH("Años promedio de escolaridad",estado),on=:Municipio)
      elseif indicador=="Años esperados de escolarización"
          dfaux=innerjoin(dfaux,getIDH("Años esperados de escolaridad",estado),on=:Municipio)
      elseif indicador=="Ingreso per cápita anual"
          dfaux=innerjoin(dfaux,getIDH("Ingreso per cápita anual",estado),on=:Municipio)
      elseif indicador=="Tasa de mortalidad infantil"
          dfaux=innerjoin(dfaux,getIDH("Tasa de mortalidad infantil",estado),on=:Municipio)
      elseif indicador=="Índice de educación"
          dfaux=innerjoin(dfaux,getIDH("Índice de educación",estado),on=:Municipio)
      elseif indicador=="Índice de salud"
          dfaux=innerjoin(dfaux,getIDH("Índice de salud",estado),on=:Municipio)
      elseif indicador=="Índice de ingreso"
          dfaux=innerjoin(dfaux,getIDH("Índice de ingreso",estado),on=:Municipio)
      elseif indicador=="IDH"
          dfaux=innerjoin(dfaux,getIDH("IDH",estado),on=:Municipio)
      elseif indicador=="Pobreza"
        dfaux=innerjoin(dfaux,getIndPobreza("Pobreza",estado),on=:Municipio)
      elseif indicador=="Pobreza extrema"
        dfaux=innerjoin(dfaux,getIndPobreza("Pobreza extrema",estado),on=:Municipio)
      elseif indicador=="Pobreza moderada"
        dfaux=innerjoin(dfaux,getIndPobreza("Pobreza moderada",estado),on=:Municipio)
      elseif indicador=="Vulnerables por carencia social"
        dfaux=innerjoin(dfaux,getIndPobreza("Vulnerables por carencia social",estado),on=:Municipio)
      elseif indicador=="Vulnerables por ingreso"
        dfaux=innerjoin(dfaux,getIndPobreza("Vulnerables por ingreso",estado),on=:Municipio)
      elseif indicador=="No pobres y no vulnerables"
        dfaux=innerjoin(dfaux,getIndPobreza("No pobres y no vulnerables",estado),on=:Municipio)
      elseif indicador=="Rezago educativo"
        dfaux=innerjoin(dfaux,getIndPobreza("Rezago educativo",estado),on=:Municipio)
      elseif indicador=="Carencia por acceso a los servicios de salud"
        dfaux=innerjoin(dfaux,getIndPobreza("Carencia por acceso a los servicios de salud",estado),on=:Municipio)
      elseif indicador=="Carencia por acceso a la seguridad social"
        dfaux=innerjoin(dfaux,getIndPobreza("Carencia por acceso a la seguridad social",estado),on=:Municipio)
      elseif indicador=="Carencia por acceso a los servicios básicos en la vivienda"
        dfaux=innerjoin(dfaux,getIndPobreza("Carencia por acceso a los servicios básicos en la vivienda",estado),on=:Municipio)
      elseif indicador=="Carencia por acceso a la alimentación"
        dfaux=innerjoin(dfaux,getIndPobreza("Carencia por acceso a la alimentación",estado),on=:Municipio)
      elseif indicador=="Población con al menos una carencia social"
        dfaux=innerjoin(dfaux,getIndPobreza("Población con al menos una carencia social",estado),on=:Municipio)
      elseif indicador=="Población con tres o más carencias sociales"
        dfaux=innerjoin(dfaux,getIndPobreza("Población con tres o más carencias sociales",estado),on=:Municipio)
      elseif indicador=="Población con ingreso inferior a la línea de bienestar"
        dfaux=innerjoin(dfaux,getIndPobreza("Población con ingreso inferior a la línea de bienestar",estado),on=:Municipio)
      elseif indicador=="Población con ingreso inferior a la línea de bienestar mínimo"
        dfaux=innerjoin(dfaux,getIndPobreza("Población con ingreso inferior a la línea de bienestar mínimo",estado),on=:Municipio)
      elseif indicador=="TOT_VIV"
        dfaux=innerjoin(dfaux,getIndIM("TOT_VIV",estado),on=:Municipio)
      elseif indicador=="VIV_REM"
        dfaux=innerjoin(dfaux,getIndIM("VIV_REM",estado),on=:Municipio)
      elseif indicador=="VIV_EMIG"
        dfaux=innerjoin(dfaux,getIndIM("VIV_EMIG",estado),on=:Municipio)
      elseif indicador=="VIV_CIRC"
        dfaux=innerjoin(dfaux,getIndIM("VIV_CIRC",estado),on=:Municipio)
      elseif indicador=="VIV_RET"
        dfaux=innerjoin(dfaux,getIndIM("VIV_RET",estado),on=:Municipio)
      elseif indicador=="IIM_2010"
        dfaux=innerjoin(dfaux,getIndIM("IIM_2010",estado),on=:Municipio)
      elseif indicador=="IIMa100"
        dfaux=innerjoin(dfaux,getIndIM("IIMa100",estado),on=:Municipio)
      elseif indicador=="GIM_2010"
        dfaux=innerjoin(dfaux,getIndIM("GIM_2010",estado),on=:Municipio)
      elseif indicador=="LUG_EDO"
        dfaux=innerjoin(dfaux,getIndIM("LUG_EDO",estado),on=:Municipio)
      elseif indicador=="LUG_NAL"
        dfaux=innerjoin(dfaux,getIndIM("LUG_NAL",estado),on=:Municipio)
      end
  end
  return dfaux
end

#Codigo para la obtencion de los datos faltantes
function downloadCD()
    fileDir=HTTP.download(url,pathCov);
    InfoZIP.unzip(fileDir,pathCov);
end

function getCovData()
    covName=string(Dates.today()-Dates.Day(1))
    covName=replace(covName,"-"=>"")
    covName=SubString(covName,3)
    covName=covName*"COVID19MEXICO.csv"
    covFile= pathCov*covName;
    ce=CSV.read(covFile,DataFrame);
    return ce
end

function downloadIP()
    inPobDir=HTTP.download(turl,path)
    InfoZIP.unzip(inPobDir,path)
end

function getIndPobreza(ind:: String,estado::String)
    ar=XLSX.readxlsx(path*"Concentrado, indicadores de pobreza.xlsx")["Concentrado municipal"]
    pobData=Array{Float64,2}
    indPob= []
    for a in ar["G5:CU5"]
        if !isequal(missing,a)
            push!(indPob,a)
        end
    end
    indPob[16]="Población con ingreso inferior a la línea de bienestar"
    headPob=ar["H6:M6"]
    for i in 1:length(headPob)
        headPob[i]=replace(headPob[i],"\n"=>" ")
    end
    dfIPob=DataFrame(ar["H9:M2465"])
    rename!(dfIPob,[Symbol(headPob[h]) for h in 1:6])
    dfIPobEx=DataFrame(ar["N9:S2465"])
    rename!(dfIPobEx,[Symbol(headPob[h]) for h in 1:6])
    dfIPobMod=DataFrame(ar["T9:Y2465"])
    rename!(dfIPobMod,[Symbol(headPob[h]) for h in 1:6])
    dfIVCS=DataFrame(ar["Z9:AE2465"])
    rename!(dfIVCS,[Symbol(headPob[h]) for h in 1:6])
    dfIVI=DataFrame(ar["AF9:AI2465"])
    rename!(dfIVI,[Symbol(headPob[h]) for h in 1:4])
    dfINPV=DataFrame(ar["AJ9:AM2465"])
    rename!(dfINPV,[Symbol(headPob[h]) for h in 1:4])
    dfIRe=DataFrame(ar["AN9:AS2465"])
    rename!(dfIRe,[Symbol(headPob[h]) for h in 1:6])
    dfICASS=DataFrame(ar["AT9:AY2465"])
    rename!(dfICASS,[Symbol(headPob[h]) for h in 1:6])
    dfICASSO=DataFrame(ar["AZ9:BE2465"])
    rename!(dfICASSO,[Symbol(headPob[h]) for h in 1:6])
    dfICCEV=DataFrame(ar["BF9:BK2465"])
    rename!(dfICCEV,[Symbol(headPob[h]) for h in 1:6])
    dfICASBV=DataFrame(ar["BL9:BQ2465"])
    rename!(dfICASBV,[Symbol(headPob[h]) for h in 1:6])
    dfICAA=DataFrame(ar["BR9:BW2465"])
    rename!(dfICAA,[Symbol(headPob[h]) for h in 1:6])
    dfIUCS=DataFrame(ar["BX9:CC2465"])
    rename!(dfIUCS,[Symbol(headPob[h]) for h in 1:6])
    dfITCS=DataFrame(ar["CD9:CI2465"])
    rename!(dfITCS,[Symbol(headPob[h]) for h in 1:6])
    dfIIILB=DataFrame(ar["CJ9:CO2465"])
    rename!(dfIIILB,[Symbol(headPob[h]) for h in 1:6])
    dfIIILBM=DataFrame(ar["CP9:CU2465"])
    rename!(dfIIILBM,[Symbol(headPob[h]) for h in 1:6])
    headINDPOB=[]
    headPob=ar["H6:CU6"]
    for i in 1:length(headPob)
        headPob[i]=replace(headPob[i],"\n"=>" ")
    end
    for i in 1:6
        push!(headINDPOB,headPob[i]*"_Pob")
    end
    for i in 7:12
        push!(headINDPOB,headPob[i]*"_PobEx")
    end
    for i in 13:18
        push!(headINDPOB,headPob[i]*"_PobMod")
    end
    for i in 19:24
        push!(headINDPOB,headPob[i]*"_VCS")
    end
    for i in 25:28
        push!(headINDPOB,headPob[i]*"_VI")
    end
    for i in 29:32
        push!(headINDPOB,headPob[i]*"_NPV")
    end
    for i in 33:38
        push!(headINDPOB,headPob[i]*"_RE")
    end
    for i in 39:44
        push!(headINDPOB,headPob[i]*"_CASS")
    end
    for i in 45:50
        push!(headINDPOB,headPob[i]*"_CASSO")
    end
    for i in 51:56
        push!(headINDPOB,headPob[i]*"_CCEV")
    end
    for i in 57:62
        push!(headINDPOB,headPob[i]*"_CASBV")
    end
    for i in 63:68
        push!(headINDPOB,headPob[i]*"_CAA")
    end
    for i in 69:74
        push!(headINDPOB,headPob[i]*"_UCS")
    end
    for i in 75:80
        push!(headINDPOB,headPob[i]*"_TCS")
    end
    for i in 81:86
        push!(headINDPOB,headPob[i]*"_IIILB")
    end
    for i in 87:92
        push!(headINDPOB,headPob[i]*"_IIILBM")
    end
    dfINDPOB=hcat(dfIPob,dfIPobEx,dfIPobMod,dfIVCS,dfIVI,dfINPV,dfIRe,dfICASS,dfICASSO,dfICCEV,dfICASBV,dfICAA,dfIUCS,dfITCS,dfIIILB,dfIIILBM;
    makeunique=true)
    rename!(dfINDPOB,[Symbol(headINDPOB[c]) for c in 1:length(headINDPOB)])
    if ind==indPob[1]
        dfIndreq=getdf2015data(ar,dfIPob,estado);
    elseif ind==indPob[2]
        dfIndreq=getdf2015data(ar,dfIPobEx,estado);
    elseif ind==indPob[3]
        dfIndreq=getdf2015data(ar,dfIPobMod,estado);
    elseif ind==indPob[4]
        dfIndreq=getdf2015data(ar,dfIVCS,estado);
    elseif ind==indPob[5]
        dfIndreq=getdf2015data(ar,dfIVI,estado);
    elseif ind==indPob[6]
        dfIndreq=getdf2015data(ar,dfINPV,estado);
    elseif ind==indPob[7]
        dfIndreq=getdf2015data(ar,dfIRe,estado);
    elseif ind==indPob[8]
        dfIndreq=getdf2015data(ar,dfICASS,estado);
    elseif ind==indPob[9]
        dfIndreq=getdf2015data(ar,dfICASSO,estado);
    elseif ind==indPob[10]
        dfIndreq=getdf2015data(ar,dfICCEV,estado);
    elseif ind==indPob[11]
        dfIndreq=getdf2015data(ar,dfICASBV,estado);
    elseif ind==indPob[12]
        dfIndreq=getdf2015data(ar,dfICAA,estado);
    elseif ind==indPob[13]
        dfIndreq=getdf2015data(ar,dfIUCS,estado);
    elseif ind==indPob[14]
        dfIndreq=getdf2015data(ar,dfITCS,estado);
    elseif ind==indPob[15]
        dfIndreq=getdf2015data(ar,dfIIILB,estado);
    elseif ind==indPob[16]
        dfIndreq=getdf2015data(ar,dfIIILBM,estado);
    elseif ind=="All"
        dfIndreq=getdf2015data(ar,dfINDPOB,estado);
    end
    return dfIndreq
end

function getIndPobreza(ind:: String)
    ar=XLSX.readxlsx(path*"Concentrado, indicadores de pobreza.xlsx")["Concentrado municipal"]
    pobData=Array{Float64,2}
    indPob= []
    for a in ar["G5:CU5"]
        if !isequal(missing,a)
            push!(indPob,a)
        end
    end
    indPob[16]="Población con ingreso inferior a la línea de bienestar"
    headPob=ar["H6:M6"]
    for i in 1:length(headPob)
        headPob[i]=replace(headPob[i],"\n"=>" ")
    end
    dfIPob=DataFrame(ar["H9:M2465"])
    rename!(dfIPob,[Symbol(headPob[h]) for h in 1:6])
    dfIPobEx=DataFrame(ar["N9:S2465"])
    rename!(dfIPobEx,[Symbol(headPob[h]) for h in 1:6])
    dfIPobMod=DataFrame(ar["T9:Y2465"])
    rename!(dfIPobMod,[Symbol(headPob[h]) for h in 1:6])
    dfIVCS=DataFrame(ar["Z9:AE2465"])
    rename!(dfIVCS,[Symbol(headPob[h]) for h in 1:6])
    dfIVI=DataFrame(ar["AF9:AI2465"])
    rename!(dfIVI,[Symbol(headPob[h]) for h in 1:4])
    dfINPV=DataFrame(ar["AJ9:AM2465"])
    rename!(dfINPV,[Symbol(headPob[h]) for h in 1:4])
    dfIRe=DataFrame(ar["AN9:AS2465"])
    rename!(dfIRe,[Symbol(headPob[h]) for h in 1:6])
    dfICASS=DataFrame(ar["AT9:AY2465"])
    rename!(dfICASS,[Symbol(headPob[h]) for h in 1:6])
    dfICASSO=DataFrame(ar["AZ9:BE2465"])
    rename!(dfICASSO,[Symbol(headPob[h]) for h in 1:6])
    dfICCEV=DataFrame(ar["BF9:BK2465"])
    rename!(dfICCEV,[Symbol(headPob[h]) for h in 1:6])
    dfICASBV=DataFrame(ar["BL9:BQ2465"])
    rename!(dfICASBV,[Symbol(headPob[h]) for h in 1:6])
    dfICAA=DataFrame(ar["BR9:BW2465"])
    rename!(dfICAA,[Symbol(headPob[h]) for h in 1:6])
    dfIUCS=DataFrame(ar["BX9:CC2465"])
    rename!(dfIUCS,[Symbol(headPob[h]) for h in 1:6])
    dfITCS=DataFrame(ar["CD9:CI2465"])
    rename!(dfITCS,[Symbol(headPob[h]) for h in 1:6])
    dfIIILB=DataFrame(ar["CJ9:CO2465"])
    rename!(dfIIILB,[Symbol(headPob[h]) for h in 1:6])
    dfIIILBM=DataFrame(ar["CP9:CU2465"])
    rename!(dfIIILBM,[Symbol(headPob[h]) for h in 1:6])
    headINDPOB=[]
    headPob=ar["H6:CU6"]
    for i in 1:length(headPob)
        headPob[i]=replace(headPob[i],"\n"=>" ")
    end
    for i in 1:6
        push!(headINDPOB,headPob[i]*"_Pob")
    end
    for i in 7:12
        push!(headINDPOB,headPob[i]*"_PobEx")
    end
    for i in 13:18
        push!(headINDPOB,headPob[i]*"_PobMod")
    end
    for i in 19:24
        push!(headINDPOB,headPob[i]*"_VCS")
    end
    for i in 25:28
        push!(headINDPOB,headPob[i]*"_VI")
    end
    for i in 29:32
        push!(headINDPOB,headPob[i]*"_NPV")
    end
    for i in 33:38
        push!(headINDPOB,headPob[i]*"_RE")
    end
    for i in 39:44
        push!(headINDPOB,headPob[i]*"_CASS")
    end
    for i in 45:50
        push!(headINDPOB,headPob[i]*"_CASSO")
    end
    for i in 51:56
        push!(headINDPOB,headPob[i]*"_CCEV")
    end
    for i in 57:62
        push!(headINDPOB,headPob[i]*"_CASBV")
    end
    for i in 63:68
        push!(headINDPOB,headPob[i]*"_CAA")
    end
    for i in 69:74
        push!(headINDPOB,headPob[i]*"_UCS")
    end
    for i in 75:80
        push!(headINDPOB,headPob[i]*"_TCS")
    end
    for i in 81:86
        push!(headINDPOB,headPob[i]*"_IIILB")
    end
    for i in 87:92
        push!(headINDPOB,headPob[i]*"_IIILBM")
    end
    dfINDPOB=hcat(dfIPob,dfIPobEx,dfIPobMod,dfIVCS,dfIVI,dfINPV,dfIRe,dfICASS,dfICASSO,dfICCEV,dfICASBV,dfICAA,dfIUCS,dfITCS,dfIIILB,dfIIILBM;
    makeunique=true)
    rename!(dfINDPOB,[Symbol(headINDPOB[c]) for c in 1:length(headINDPOB)])
    if ind==indPob[1]
        dfIndreq=getdf2015data(ar,dfIPob);
    elseif ind==indPob[2]
        dfIndreq=getdf2015data(ar,dfIPobEx);
    elseif ind==indPob[3]
        dfIndreq=getdf2015data(ar,dfIPobMod);
    elseif ind==indPob[4]
        dfIndreq=getdf2015data(ar,dfIVCS);
    elseif ind==indPob[5]
        dfIndreq=getdf2015data(ar,dfIVI);
    elseif ind==indPob[6]
        dfIndreq=getdf2015data(ar,dfINPV);
    elseif ind==indPob[7]
        dfIndreq=getdf2015data(ar,dfIRe);
    elseif ind==indPob[8]
        dfIndreq=getdf2015data(ar,dfICASS);
    elseif ind==indPob[9]
        dfIndreq=getdf2015data(ar,dfICASSO);
    elseif ind==indPob[10]
        dfIndreq=getdf2015data(ar,dfICCEV);
    elseif ind==indPob[11]
        dfIndreq=getdf2015data(ar,dfICASBV);
    elseif ind==indPob[12]
        dfIndreq=getdf2015data(ar,dfICAA);
    elseif ind==indPob[13]
        dfIndreq=getdf2015data(ar,dfIUCS);
    elseif ind==indPob[14]
        dfIndreq=getdf2015data(ar,dfITCS);
    elseif ind==indPob[15]
        dfIndreq=getdf2015data(ar,dfIIILB);
    elseif ind==indPob[16]
        dfIndreq=getdf2015data(ar,dfIIILBM);
    elseif ind=="All"
        dfIndreq=getdf2015data(ar,dfINDPOB);
    end
    return dfIndreq
end

function getdf2015data(ar::XLSX.Worksheet,dfaux:: DataFrame,estado::String)
        munPob=ar["E9:E2465"]
        estPob=ar["C9:C2465"]
        dfmunPob=DataFrame(munPob,["Municipio"])
        dfestPob=DataFrame(estPob,["Estado"])
        dfPob=hcat(dfmunPob,dfaux)
        dfPob=hcat(dfestPob,dfPob)
        notoddAR=collect(2:2:length(names(dfaux)))
        headPob2015=[]
        sin=[]
        for i in 1:length(names(dfPob))
            push!(sin,Symbol(names(dfPob)[i]))
        end
        for n in notoddAR
            push!(headPob2015,sin[n])
        end
        select(dfPob,Not(headPob2015))
        munau=[]
        for k in keys(diccionario_municipios[parse(Int64,get(diccionario_estados,estado,"Not founded"))])
          push!(munau,k)
        end
        dfmunIM=DataFrame(Municipio=munau)
        dfmunIM=innerjoin(dfmunIM,dfPob,on=:Municipio)
        dfmunIM=innerjoin(dfmunIM,DataFrame(Estado=[estado]),on=:Estado)
        return select(dfmunIM,Not(:Estado))
end

function downloadIIM()
    HTTP.download(murl,path)
end

function getIndIM(field:: String,estado::String)
    dfIIM=DataFrame(ExcelFiles.load(path*"IIM2010_BASEMUN.xls","IIM2010_BASEMUN"))
    ar=[:ENT,:MUN]
    select!(dfIIM,Not(ar))
    rename!(dfIIM,:NOM_MUN=>"Municipio")
    rename!(dfIIM,:NOM_ENT=>"Estado")
    if field==names(dfIIM)[2]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[2])])
    elseif field==names(dfIIM)[3]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[3])])
    elseif field==names(dfIIM)[4]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[4])])
    elseif field==names(dfIIM)[5]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[5])])
    elseif field==names(dfIIM)[6]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[6])])
    elseif field==names(dfIIM)[7]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[7])])
    elseif field==names(dfIIM)[8]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[8])])
    elseif field==names(dfIIM)[9]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[9])])
    elseif field==names(dfIIM)[10]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[10])])
    elseif field==names(dfIIM)[11]
        dfret=select(dfIIM,[:Estado,:Municipio,Symbol(names(dfIIM)[11])])
    elseif field=="All"
        dfret=dfIIM
    end
    munau=[]
    for k in keys(diccionario_municipios[parse(Int64,get(diccionario_estados,estado,"Not founded"))])
      push!(munau,k)
    end
    dfmunIM=DataFrame(Municipio=munau)
    dfmunIM=innerjoin(dfmunIM,dfret,on=:Municipio)
    dfmunIM=innerjoin(dfmunIM,DataFrame(Estado=[estado]),on=:Estado)
    return select(dfmunIM,Not(:Estado))
end

function getIDH(componente::String,estado::String)
    adh=XLSX.readxlsx(path*"Indice de Desarrollo Humano Municipal 2010 2015.xlsx")["IDH municipal 2015"]
    headIDH=adh["C8:L8"]
    idhData=adh["C10:L2469"]
    tfd=DataFrame(idhData)
    for i in 1:length(headIDH)
        rename!(tfd,Symbol("x$i")=>(headIDH[i]))
    end
    tfd=dropmissing(tfd)
    if componente==names(tfd)[3]
        dfret=select(tfd,[:Estado,:Municipio,Symbol(names(tfd)[3])])
    elseif componente==names(tfd)[4]
        dfret=select(tfd,[:Estado,:Municipio,Symbol(names(tfd)[4])])
    elseif componente=="Ingreso per cápita anual"
        dfret=select(tfd,[:Estado,:Municipio,Symbol(names(tfd)[5])])
    elseif componente==names(tfd)[6]
        dfret=select(tfd,[:Estado,:Municipio,Symbol(names(tfd)[6])])
    elseif componente==names(tfd)[7]
        dfret=select(tfd,[:Estado,:Municipio,Symbol(names(tfd)[7])])
    elseif componente==names(tfd)[8]
        dfret=select(tfd,[:Estado,:Municipio,Symbol(names(tfd)[8])])
    elseif componente==names(tfd)[9]
        dfret=select(tfd,[:Estado,:Municipio,Symbol(names(tfd)[9])])
    elseif componente=="IDH"
        dfret=select(tfd,[:Estado,:Municipio,Symbol(names(tfd)[10])])
    elseif componente=="All"
        dfret=tfd
    end
    munau=[]
    for k in keys(diccionario_municipios[parse(Int64,get(diccionario_estados,estado,"Not founded"))])
      push!(munau,k)
    end
    dfmunIM=DataFrame(Municipio=munau)
    dfmunIM=innerjoin(dfmunIM,dfret,on=:Municipio)
    dfmunIM=innerjoin(dfmunIM,DataFrame(Estado=[estado]),on=:Estado)
    return select(dfmunIM,Not(:Estado))
end

function getIDH(componente::String)
    adh=XLSX.readxlsx(path*"Indice de Desarrollo Humano Municipal 2010 2015.xlsx")["IDH municipal 2015"]
    headIDH=adh["D8:L8"]
    idhData=adh["D10:L2469"]
    tfd=DataFrame(idhData)
    for i in 1:length(headIDH)
        rename!(tfd,Symbol("x$i")=>(headIDH[i]))
    end
    tfd=dropmissing(tfd)
    if componente==names(tfd)[2]
        dfret=select(tfd,[:Municipio,Symbol(names(tfd)[2])])
    elseif componente==names(tfd)[3]
        dfret=select(tfd,[:Municipio,Symbol(names(tfd)[3])])
    elseif componente=="Ingreso per cápita anual"
        dfret=select(tfd,[:Municipio,Symbol(names(tfd)[4])])
    elseif componente==names(tfd)[5]
        dfret=select(tfd,[:Municipio,Symbol(names(tfd)[5])])
    elseif componente==names(tfd)[6]
        dfret=select(tfd,[:Municipio,Symbol(names(tfd)[6])])
    elseif componente==names(tfd)[7]
        dfret=select(tfd,[:Municipio,Symbol(names(tfd)[7])])
    elseif componente==names(tfd)[8]
        dfret=select(tfd,[:Municipio,Symbol(names(tfd)[8])])
    elseif componente=="IDH"
        dfret=select(tfd,[:Municipio,Symbol(names(tfd)[9])])
    elseif componente=="All"
        dfret=tfd
    end
    return dfret
end

function codPos_municipio(estado::String,municipio::String)
    headCP=[:d_codigo,:d_asenta,:d_tipo_asenta,:D_mnpio]
    if estado=="Aguascalientes"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Aguascalientes"])["A2:D1357"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Baja California"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Baja_California"])["A2:D2437"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Baja California Sur"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Baja_California_Sur"])["A2:D988"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Campeche"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Campeche"])["A2:D1310"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Coahuila de Zaragoza"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Coahuila_de_Zaragoza"])["A2:D3967"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Colima"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Colima"])["A2:D834"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Chiapas"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Chiapas"])["A2:D7639"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Chihuahua"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Chihuahua"])["A2:D9561"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Ciudad de México"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Distrito_Federal"])["A2:D1516"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Durango"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Durango"])["A2:D7049"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Guanajuato"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Guanajuato"])["A2:D10050"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Guerrero"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Guerrero"])["A2:D4793"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Hidalgo"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Hidalgo"])["A2:D6090"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Jalisco"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Jalisco"])["A2:D5741"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="México"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["México"])["A2:D8158"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Michoacán de Ocampo"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Michoacán_de_Ocampo"])["A2:D10182"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Morelos"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Morelos"])["A2:D1744"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Nayarit"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Nayarit"])["A2:D1980"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Nuevo León"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Nuevo_León"])["A2:D4878"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Oaxaca"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Oaxaca"])["A2:D6063"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Puebla"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Puebla"])["A2:D5428"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Querétaro"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Querétaro"])["A2:D3100"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Quintana Roo"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Quintana_Roo"])["A2:D1150"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="San Luis Potosí"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["San_Luis_Potosí"])["A2:D5982"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Sinaloa"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Sinaloa"])["A2:D4165"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Sonora"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Sonora"])["A2:D8734"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Tabasco"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Tabasco"])["A2:D2645"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Tamaulipas"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Tamaulipas"])["A2:D3281"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Tlaxcala"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Tlaxcala"])["A2:D1443"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Veracruz de Ignacio de la Llave"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Veracruz_de_Ignacio_de_la_Llave"])["A2:D8950"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Yucatán"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Yucatán"])["A2:D1643"]
      dfCPA=DataFrame(CPdata,headCP)
    elseif estado=="Zacatecas"
      CPdata=(XLSX.readxlsx(path*"CPdescarga.xlsx")["Zacatecas"])["A2:D1846"]
      dfCPA=DataFrame(CPdata,headCP)
    end
        dfaux=DataFrame(D_mnpio=[municipio])
        return innerjoin(dfaux,dfCPA,on= :D_mnpio)
end

function getIndINEGI(estado::String,indicador::String)
    if Sys.iswindows()
      dfIndINE=CSV.read(pathINEGI*estado*"\\datos_"*indicador*"_"*estado*".csv",DataFrame);
 
    elseif Sys.islinux()
      dfIndINE=CSV.read(pathINEGI*estado*"/datos_"*indicador*"_"*estado*".csv",DataFrame);
    end
    return dfIndINE
end

function getExtTer(estado:: String)
  headET=[:Municipio,:Total]
  if estado=="Aguascalientes"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B11"],headET)
  elseif estado=="Baja California"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B7"],headET)
  elseif estado=="Baja California Sur"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B6"],headET)
  elseif estado=="Campeche"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B13"],headET)
  elseif estado=="Coahuila de Zaragoza"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B39"],headET)
  elseif estado=="Colima"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B11"],headET)
  elseif estado=="Chiapas"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B125"],headET)
  elseif estado=="Chihuahua"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B68"],headET)
  elseif estado=="Ciudad de México"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B17"],headET)
  elseif estado=="Durango"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B40"],headET)
  elseif estado=="Guanajuato"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B47"],headET)
  elseif estado=="Guerrero"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B82"],headET)
  elseif estado=="Hidalgo"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B85"],headET)
  elseif estado=="Jalisco"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B126"],headET)
  elseif estado=="México"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B126"],headET)
  elseif estado=="Michoacán de Ocampo"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B114"],headET)
  elseif estado=="Morelos"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B37"],headET)
  elseif estado=="Nayarit"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B21"],headET)
  elseif estado=="Nuevo León"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B52"],headET)
  elseif estado=="Oaxaca"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B571"],headET)
  elseif estado=="Puebla"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B218"],headET)
  elseif estado=="Querétaro"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B19"],headET)
  elseif estado=="Quintana Roo"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B10"],headET)
  elseif estado=="San Luis Potosí"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B59"],headET)
  elseif estado=="Sinaloa"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B19"],headET)
  elseif estado=="Sonora"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B73"],headET)
  elseif estado=="Tabasco"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B18"],headET)
  elseif estado=="Tamaulipas"
      dfET=DataFrame((XLSX.readxlsx(path*"Extension territorial.xlsx")[estado])["A2:B44"],headET)
  elseif estado=="Tlaxcala"
      dfET=DataFrame((XLSX.readxlsx(path*"\\"*"Extension territorial.xlsx")[estado])["A2:B61"],headET)
  elseif estado=="Veracruz de Ignacio de la Llave"
      dfET=DataFrame((XLSX.readxlsx(path*"\\"*"Extension territorial.xlsx")[estado])["A2:B213"],headET)
  elseif estado=="Yucatán"
      dfET=DataFrame((XLSX.readxlsx(path*"\\"*"Extension territorial.xlsx")[estado])["A2:B106"],headET)
  elseif estado=="Zacatecas"
      dfET=DataFrame((XLSX.readxlsx(path*"\\"*"Extension territorial.xlsx")[estado])["A2:B59"],headET)
  end
      return dfET
end

end #module
