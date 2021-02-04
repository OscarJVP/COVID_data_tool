url="http://datosabiertos.salud.gob.mx/gobmx/salud/datos_abiertos/datos_abiertos_covid19.zip";
turl="https://www.coneval.org.mx/Medicion/Documents/Pobreza_municipal/Concentrado_indicadores_de_pobreza.zip";
murl="http://www.conapo.gob.mx/work/models/CONAPO/intensidad_migratoria/base_completa/IIM2010_BASEMUN.xls";

#=
path=chop(pathof(COVID_data_tool), tail=22)*"Docs";
pathCov=chop(pathof(COVID_data_tool), tail=22)*"Docs\\Cov_data";
pathINEGI=chop(pathof(COVID_data_tool), tail=22)*"Docs\\Datos INEGI\\Datos ";
=#

if Sys.iswindows()
    path=chop(pathof(COVID_data_tool), tail=22)*"Docs";
    pathCov=chop(pathof(COVID_data_tool), tail=22)*"Docs\\Cov_data";
    pathINEGI=chop(pathof(COVID_data_tool), tail=22)*"Docs\\Datos INEGI\\Datos ";
end

if Sys.islinux()
    path=chop(pathof(COVID_data_tool), tail=22)*"Docs";
    pathCov=chop(pathof(COVID_data_tool), tail=22)*"Docs\\Cov_data";
    pathINEGI=chop(pathof(COVID_data_tool), tail=22)*"Docs\\Datos INEGI\\Datos ";
end
