url="http://datosabiertos.salud.gob.mx/gobmx/salud/datos_abiertos/datos_abiertos_covid19.zip";
turl="https://www.coneval.org.mx/Medicion/Documents/Pobreza_municipal/Concentrado_indicadores_de_pobreza.zip";
murl="http://www.conapo.gob.mx/work/models/CONAPO/intensidad_migratoria/base_completa/IIM2010_BASEMUN.xls";

if Sys.iswindows()
    path=chop(@__DIR__, tail=3)*"Docs\\";
    pathCov=chop(@__DIR__, tail=3)*"Docs\\Cov_data\\";
    pathINEGI=chop(@__DIR__, tail=3)*"Docs\\Datos INEGI\\Datos ";
    pathCSV="C:\\archivos_CSV_COVID_data_tool"
elseif Sys.islinux()
    path=chop(@__DIR__, tail=3)*"Docs/";
    pathCov=chop(@__DIR__, tail=3)*"Docs/Cov_data/";
    pathINEGI=chop(@__DIR__, tail=3)*"Docs/Datos INEGI/Datos ";
    pathCSV="/home/archivos_CSV_COVID_data_tool"
end
