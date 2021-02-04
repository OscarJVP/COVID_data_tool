# COVID_data_tool
Paquetería de JULIA creada con el fín de unir datos abiertos sobre casos COVID-19 y demografía de México.\
Probada con JULIA 1.4.2 y 1.5.3

### Prerrequisitos
Paquetes de JULIA necesarios para el funcionamiento de la paquetería.\
    `HTTP`\
    `DataFrames`\
    `CSV`\
    `JSON`\
    `InfoZIP`\
    `ZipFile`\
    `XLSX`\
    `ExcelFiles`\
    `Dates`\
Pueden instalarse con el administrador de paquetes de JULIA pulsando la tecla `]` en el REPL\
    `add HTTP DataFrames CSV JSON InfoZIP ZipFile XLSX ExcelFiles Dates`\
    \
    ![](images/prerrequisitos.GIF)


### Instalación
Haciendo uso del REPL de JULIA presiona la tecla `]` para al administrador de paquetes de JULIA e ingresar\
    `add https://github.com/OscarJVP/COVID_data_tool.jl`\
    \
    ![](images/instalacion_1.GIF)
    \
Regresar a la línea de comandos de JULIA presionando la tecla `backspace` e ingresar\
    `using COVID_data_tool`\
    \
    ![](images/instalacion_2.gif)
    \
Por último ejecutar la función `COVID_data_tool.downloadCD()`, esta descargara datos necesarios para el funcionamiento de la paquetería.\
    \
    ![](images/instalacion_3.GIF)
    \
Puedes probarla con\
    `COVID_data_tool.indicadores_disponibles()`\
    \
    ![](images/instalacion_4.GIF)


### Funciones
`indicadores_disponibles()`\
Muestra la lista de indicadores disponibles para consulta.\
\

`lista_ComponentesIDH()`\
Muestra la lista de componentes relacionados al IDH disponibles para consulta.\
\

`lista_IndicadoresPobreza()`\
Muestra la lista de indicadores de pobreza disponibles para consulta.\
\

`dato_estado(indicador::String, estado::String)`\
Recibe el indicador a consultar como `String` y el estado como `String`.\
Crea un .csv con la información deseada en la entrada de la función y muestra el nombre del archivo creado con éxito.\
\

`conjunto_estado(indicadores::Vector{String}, estado::String)`\
Recibe los indicadores a consultar como un `array` de tipo `String`,el estado como `String` y el municipio como `String`.\
Crea un .csv con la información deseada en la entrada de la función y muestra el nombre del archivo creado con éxito.\
\

`datos_municipio(indicadores, estado::String, municipio::String)`\
Recibe los indicadores a consultar como un `array` de tipo `String`,el estado como `String` y el municipio como `String`.\
Crea un .csv con la información deseada en la entrada de la función y muestra el nombre del archivo creado con éxito.\
\

`downloadCD()`\
Realiza la descarga de datos acerca del COVID-19 para poder ser consultados.
\


### Notas
    * Las funciones que requieran un estado como entrada necesitan el nombre oficial del estado v. gr. Michoacán se deben introducir como Michoacán de Ocampo.\
    * Las funciones que requieran un indicador como entrada necesitan introducirse como están en el listado. Este se puede observar utilizando la función `indicadores_disponibles().`
    * Todos los archivos .csv se generan en una carpeta con nombre archivos_CSV_COVID_data_tool dentro de la raíz del disco duro (por lo general C:\\archivos_CSV_COVID_data_tool).

## Equipo de Trabajo
Deep Alpha\
<img src="images/deep_alpha.jpg" width="200">\
    - **Carlos Espadín** - *Director de proyecto* -\
    - **Luis Moysén** - *SCRUM Master* -\
    - **Luis Roa** - *Miembro del equpo desarrollador* -\
    - **Rodrígo Vazquez** - *Miembro del equpo desarrollador* -\
    - **Oscar Vargas** - *Miembro del equpo desarrollador* -\
    - **Susan Rodríguez** - *Tester* -\
    - **Eduardo Bacelis** - *Tester* -

## Licencia
Proyecto bajo [MIT License](LICENSE.md) licencia del MIT - Consulte [LICENSE.md](LICENSE.md) para mas detalles.
