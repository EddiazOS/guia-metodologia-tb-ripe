#import "lib.typ": frontiers

#show: frontiers.with(
  title: "Guía Metodológica Estandarizada: Análisis de Disbiosis Intestinal en Tuberculosis (RIPE) mediante Secuenciación Nanopore",
  running-title: "Metodología Nanopore Microbioma TB-RIPE",
  
  authors: (
    (
      name: "José Luis Villadiego",
      affiliations: ("1", "2"),
    ),
    (
      name: "Nelson Enrique Arenas Suarez",
      affiliations: ("2",),
    ),
    (
      name: "Edgar Luis Diaz",
      affiliations: ("1", "2", "*"),
    ),
  ),
  
  affiliations: (
    "Grupo de Investigación en Micobacterias, Facultad de Medicina, Universidad de Cartagena, Cartagena, Colombia",
    "Centro de Investigaciones Biomédicas (CIB), Cartagena, Colombia"
  ),
  
  corresponding-author: (
    name: "Edgar Luis Diaz",
    email: "eldiazo@unal.edu.co",
  ),
  
  keywords: (
    "Microbiota", 
    "Tuberculosis", 
    "Oxford Nanopore", 
    "EMU", 
    "ANCOM-BC2", 
    "q2-longitudinal", 
    "Composicionalidad"
  ),
  
  abstract: [
    El tratamiento antituberculoso de primera línea (terapia RIPE) genera alteraciones profundas en la microbiota intestinal, con implicaciones sustanciales en la recuperación sistémica y la salud a largo plazo del paciente. La reciente adopción de la tecnología de secuenciación de nanoporos (Oxford Nanopore Technologies) para la amplificación del gen 16S rRNA de longitud completa exige una reevaluación absoluta de los paradigmas bioinformáticos heredados de plataformas de lecturas cortas. Este manuscrito detalla un flujo de trabajo metodológico exhaustivo, estandarizado y reproducible para el proyecto de investigación TB-RIPE. En esta guía se justifica teóricamente la exclusión de enfoques descriptivos propensos a artefactos visuales, como los mapas de calor complejos (ComplexHeatmap), en favor de un marco analítico inferencial robusto a la composicionalidad intrínseca de los datos del microbioma. La metodología aborda progresivamente desde el control de calidad adaptado a lecturas largas, pasando por la clasificación taxonómica probabilística mediante Expectation-Maximization (EMU), hasta el modelado de datos longitudinales (q2-longitudinal) y el análisis de abundancia diferencial con corrección de sesgos (ANCOM-BC2). Este documento sirve como manual operativo y marco teórico (Standard Operating Procedure) diseñado para garantizar la solidez estadística y la validez biológica en cohortes clínicas de tamaño moderado.
  ],
  
  citation-style: "vancouver",
  line-numbers: false,
)

= 1. Introducción General

La tuberculosis (TB) pulmonar continúa siendo un desafío global de salud pública. Su abordaje farmacológico mediante el esquema RIPE (Rifampicina, Isoniacida, Pirazinamida, Etambutol) ha demostrado ser sumamente eficaz en la erradicación de *Mycobacterium tuberculosis*. No obstante, la administración prolongada de este potente cóctel antimicrobiano induce alteraciones severas y a menudo persistentes en la estructura de la comunidad microbiana intestinal (disbiosis).

Históricamente, los estudios de metataxonómica para la evaluación de estas alteraciones han dependido de la secuenciación de amplicones cortos (típicamente las regiones hipervariables V3-V4 del gen 16S rRNA) mediante plataformas como Illumina. Si bien esto fue el estándar de oro durante la década pasada, su capacidad para discriminar microorganismos a nivel de especie es inherentemente limitada debido a la falta de información filogenética en un fragmento de apenas 300-400 pares de bases.

En respuesta a esta limitación, el presente proyecto ha pivotado hacia la **tecnología de secuenciación de tercera generación de Oxford Nanopore Technologies (ONT)**. ONT permite la secuenciación de moléculas individuales de ADN en tiempo real, facilitando la lectura del gen 16S rRNA en su totalidad (~1500 pares de bases). Esta transición metodológica proporciona una resolución taxonómica sin precedentes. Sin embargo, el perfil de error de ONT (históricamente dominado por inserciones y deleciones) requiere el abandono total de herramientas diseñadas para Illumina (como DADA2 o el obsoleto PyroNoise) y la adopción de algoritmos probabilísticos diseñados para lecturas largas y ruidosas.

El presente documento establece formalmente el nuevo *Standard Operating Procedure* (SOP) bioinformático para el análisis de los datos generados por la Universidad del Valle. 

= 2. Consideraciones Teóricas Centrales

Antes de detallar el flujo de trabajo, es imperativo establecer el marco conceptual sobre la naturaleza matemática de los datos de secuenciación de alto rendimiento.

Los datos del microbioma son, por definición matemática, **datos composicionales** @gloor2017microbiome. La secuenciación impone un límite superior arbitrario (la profundidad de secuenciación total) al número de lecturas obtenidas por muestra. En consecuencia, las abundancias observadas son proporciones relativas, no cantidades absolutas. Si un taxón dominante sufre una disminución real debido al tratamiento con Rifampicina, todos los demás taxones presentes en la muestra mostrarán un aumento artificial y espurio en su abundancia relativa. Ignorar este hecho matemático (analizando proporciones directas con pruebas de Kruskal-Wallis o mapas de calor basados en distancia Euclidiana) genera tasas inaceptables de falsos positivos y agrupamientos biológicamente carentes de significado. 

Por esta razón, la metodología descrita a continuación está fundamentada enteramente en transformaciones y métricas conscientes de la composicionalidad (ej. Centered Log-Ratio y Aitchison distance).

= 3. Flujo de Trabajo Metodológico

== Fase 0: Coordinación de Secuenciación

El punto de partida del análisis no ocurre frente al computador, sino en la correcta estipulación de los parámetros de entrega de datos con el proveedor de secuenciación (Universidad del Valle).

=== Justificación
La exactitud del posterior análisis taxonómico con Nanopore depende abrumadoramente del modelo computacional utilizado por el proveedor para convertir la señal eléctrica del poro en secuencias de nucleótidos (proceso de *basecalling*). Un modelo rápido pero impreciso arruinará la resolución a nivel de especie, sin importar el rigor del downstream bioinformático.

=== Procedimiento
1.  Solicitar explícitamente que el *basecalling* se ejecute utilizando el modelo de mayor precisión disponible (Super-Accurate o *Sup* model) en herramientas como Guppy o Dorado.
2.  Exigir la entrega de archivos `FASTQ` demultiplexados, separando las lecturas correspondientes a cada muestra biológica basándose en los códigos de barras (barcodes) del kit SQK-16S024 (o equivalente).
3.  Requerir el reporte de calidad crudo de la corrida de secuenciación.

=== Glosario de la Fase 0
- **Basecalling:** Algoritmo de redes neuronales que traduce fluctuaciones de corriente iónica (squiggles) en secuencias (A, C, T, G) con scores de calidad asociados.
- **Demultiplexing:** Separación algorítmica de un *pool* masivo de secuencias en archivos individuales (uno por paciente/tiempo) utilizando secuencias únicas denominadas *barcodes*.
- **FASTQ:** Formato estándar de la industria que almacena la secuencia biológica junto con un carácter ASCII que representa matemáticamente la probabilidad de error de cada nucleótido individual.

== Fase 1: Control de Calidad (QC) 

La primera etapa computacional implica purgar los datos de secuencias basuras, quimeras, y fragmentos que carecen de longitud biológica esperada.

=== Fundamento Teórico
A diferencia de Illumina, donde la degradación de la calidad ocurre drásticamente al final de la lectura, en ONT el error se distribuye uniformemente a lo largo de toda la secuencia. Las herramientas clásicas que truncan lecturas en puntos específicos no tienen sentido aquí. En su lugar, se requiere un filtrado global de la secuencia por su puntaje de calidad promedio (*Phred Score*) y por su longitud geométrica. Un gen 16S bacteriano tiene ~1500 pb; por lo tanto, lecturas de 400 pb en un experimento ONT representan amplificaciones inespecíficas, fragmentación mecánica o abortos de lectura en el poro.

=== Procedimiento y Justificación
Se empleará `NanoPlot` @decoster2018nanopack para obtener estadísticas globales. Posteriormente, `Porechop` se utilizará para recortar adaptadores sintéticos que pudieron haber quedado ligados al inicio o final de las lecturas. 

Finalmente, `NanoFilt` aplicará los dos filtros críticos:
- *Quality filter (Q > 10)*: Garantiza que la lectura tenga al menos un 90% de exactitud base.
- *Length filter (1300 < L < 1700 pb)*: Retiene estrictamente los amplicones que corresponden a un gen 16S completo, desechando ruido del ecosistema.

=== Glosario de la Fase 1
- **Phred Score (Q):** Expresión logarítmica de la probabilidad de que una base haya sido identificada incorrectamente ($Q = -10 \log_{10} P$).
- **Quimera:** Artefacto de laboratorio donde la ADN polimerasa fusiona fragmentos de dos bacterias distintas durante la PCR, generando un gen falso híbrido.
- **Adaptadores:** Fragmentos de ADN ligados artificialmente a los extremos de la muestra, necesarios para la química del motor de secuenciación (translocación por el poro).

== Fase 2: Clasificación Taxonómica Robusta (EMU)

Esta etapa es el núcleo analítico donde se responde a la pregunta de "quién está ahí".

=== Fundamento Teórico
Los pipelines tradicionales para microbioma (ej. QIIME 2 clásico) suelen usar clasificadores Naive Bayes entrenados con secuencias modelo. Estos fallan dramáticamente con datos ONT, ya que la tasa de inserciones/deleciones engaña a los *k-mers* del algoritmo bayesiano. 
Para resolver esto, se adopta **EMU** @curry2022emu, un algoritmo diseñado ex profeso para ONT que emplea un marco de **Expectation-Maximization (EM)**. El algoritmo evalúa primero qué taxones de una base de datos (como SILVA 138) encajan mejor con las lecturas (alineamiento). En presencia de alineamientos ambiguos (una lectura que parece pertenecer a dos especies diferentes), el modelo EM ajusta iterativamente las probabilidades de asignación basándose en las abundancias globales de la comunidad, logrando separar especies estrechamente relacionadas.

=== Procedimiento y Justificación
Se ejecutará EMU sobre los archivos `FASTQ` filtrados contra la base de datos `EMU-database` (una versión curada del proyecto rrnDB y NCBI). La salida principal es una tabla de abundancias relativas (o *counts* inferidos) a nivel de especie. Esto moderniza por completo la metodología del obsoleto agrupamiento por OTUs al 97% documentado en iteraciones pasadas del proyecto.

=== Glosario de la Fase 2
- **Expectation-Maximization (EM):** Método iterativo para encontrar estimaciones de máxima verosimilitud de parámetros en modelos estadísticos con variables latentes no observadas.
- **ASV (Amplicon Sequence Variant):** Secuencias inferidas exactamente, sin agrupar por un límite de similitud arbitrario. EMU genera un equivalente probabilístico de ASVs.
- **Base de Datos SILVA:** Repositorio exhaustivo y sometido a curación manual de secuencias de ARN ribosomal, el estándar actual en taxonomía bacteriana.

== Fase 3: Evaluación de la Estructura y Diversidad

Cálculo de la complejidad ecológica intra- e inter-muestra. Se ejecuta tras importar la matriz de EMU al entorno estandarizado de QIIME 2 @bolyen2019qiime.

=== Fundamento Teórico y Procedimiento
Para la **diversidad alfa** (complejidad dentro de un solo paciente), se calcularán el Índice de Shannon (que mide entropía termodinámica considerando riqueza y uniformidad) y el Faith's Phylogenetic Diversity (que suma las ramas del árbol evolutivo presentes).

Para la **diversidad beta** (disimilitud entre pacientes o puntos temporales), es imperativo abordar la composicionalidad @gloor2017microbiome. Se reemplazará la métrica de Bray-Curtis (matemáticamente inapropiada para datos no normalizados de distinta profundidad de librería) por la métrica de **Aitchison**. Ésta se obtiene aplicando una transformación *Centered Log-Ratio (CLR)* a la matriz de abundancias, seguida de un cálculo simple de distancia Euclidiana en el nuevo espacio proyectado. Adicionalmente, se calculará UniFrac Ponderado, el cual penaliza las diferencias utilizando las distancias filogenéticas.

Las diferencias se probarán estadísticamente usando análisis de varianza por permutaciones (PERMANOVA).

=== Glosario de la Fase 3
- **Centered Log-Ratio (CLR):** Transformación logarítmica donde cada valor se divide por la media geométrica de su muestra, trasladando los datos composicionales (simplex) al espacio real simétrico.
- **Aitchison Distance:** Distancia euclidiana calculada sobre una matriz de datos previamente transformada por CLR.
- **PERMANOVA:** Prueba no paramétrica que evalúa si los centroides de dispersión de las muestras agrupadas difieren significativamente en un espacio multidimensional.

== Fase 4: Modelado de Dinámica Longitudinal

El proyecto TB-RIPE implica medidas repetidas en T0, T2, T6 y T9. Evaluar esto mediante comparaciones transversales (t-tests independientes) constituye un error analítico grave.

=== Fundamento Teórico y Procedimiento
Se aplicará el plugin `q2-longitudinal` @bokulich2018q2. Esta herramienta implementa enfoques de **Linear Mixed Effects (LME)**. En estos modelos, el "Tratamiento" y el "Tiempo" son considerados *efectos fijos* (la señal principal que buscamos aislar), mientras que el "Sujeto/Paciente" es considerado un *efecto aleatorio*. Esto permite que el modelo entienda que T0 y T2 de José son métricas correlacionadas, filtrando el inmenso ruido introducido por la dieta individual basal de José frente a la de otros pacientes.

Asimismo, se utilizarán las *First Distances*, que calculan la tasa de cambio microbiológico entre un punto y el consecutivo (ej. T0 a T2 frente a T2 a T6) para demostrar en qué fase de la terapia farmacológica ocurre el choque disbótico primario.

=== Glosario de la Fase 4
- **Volatilidad Microbiológica:** Medida empírica de qué tan inestable o cambiante es el ecosistema intestinal a través de múltiples ventanas temporales.
- **Efectos Mixtos Lineales (LME):** Modelos de regresión avanzada que integran variables predictoras poblacionales (efectos fijos) con variables de idiosincrasia individual (efectos aleatorios).
- **First Distances:** Distribución de distancias de diversidad beta calculadas exclusivamente entre pares de muestras temporalmente adyacentes del mismo individuo.

== Fase 5: Abundancia Diferencial y Descarte del Enfoque Visual Puro

El núcleo final del proyecto consiste en descubrir biomarcadores: qué géneros y especies sucumben ante RIPE y cuáles medran en el vacío ecológico.

=== Procedimiento y Justificación
Se utilizará la herramienta **ANCOM-BC2** (Analysis of Compositions of Microbiomes with Bias Correction 2) @lin2020ancom. Este marco estadístico estima un factor de sesgo invisible inducido por el muestreo de secuenciación de manera iterativa y ejecuta comparaciones directas, controlando estrictamente la tasa de descubrimiento falso (FDR).

=== Justificación para la Exclusión de ComplexHeatmap
El diseño analítico previo contemplaba la creación de mapas de calor anotados usando el entorno `ComplexHeatmap` @gu2016complex. Si bien esta herramienta es el patrón oro visual en la transcriptómica del cáncer, su aplicación en metataxonómica requiere cautela extrema. 

Un mapa de calor agrupa columnas (pacientes) y filas (taxones) asumiendo una matriz espacial Euclidiana. Al forzar esta representación sobre la nube de datos dispersos de un microbioma fuertemente influido por la idiosincrasia del sujeto, el dendrograma tenderá a crear agrupamientos *espurios* o "microbiotipos visuales" que engañan la percepción del investigador. Este fenómeno se conoce como *apofenia estadística*. El heatmap describe patrones co-ocurrentes, pero carece de un estimador de covarianza, valor-*p*, o corrección de sesgos composicionales inherente a ANCOM-BC2.

Al centrar el trabajo de tesis exclusivamente en los cambios estructurales, delegar el hallazgo de resultados al dendrograma de un heatmap compromete la robustez inferencial. Las conclusiones del trabajo deben estar sustentadas en los coeficientes beta y los q-valores de ANCOM-BC2 y del LME, descartando la dependencia de visualizaciones complejas que simulan, erróneamente, solidez estadística formal.

=== Glosario de la Fase 5
- **Bias Correction (Corrección de Sesgo):** Proceso algebraico interno en ANCOM que calibra la pérdida de la noción de masa total (biomasa absoluta) intrínseca en todos los datos de High-Throughput Sequencing.
- **FDR (False Discovery Rate):** Probabilidad esperada de rechazar la hipótesis nula incorrectamente al realizar múltiples comparaciones en simultáneo. Controlado comúnmente con el algoritmo de Benjamini-Hochberg.
- **Apofenia Estadística:** Identificación cognitiva errónea de patrones o conexiones significativas en datos esencialmente ruidosos o aleatorios, frecuentemente catalizada por herramientas de ordenamiento jerárquico incontrolado.

= 4. Conclusión

La reformulación metodológica descrita provee a este proyecto de una armadura bioinformática contemporánea y de altísimo nivel. El flujo de trabajo no solo aborda las singularidades algorítmicas de la tecnología de nanoporos de tercera generación mediante EMU, sino que blindaje los análisis de la crítica matemática frecuentemente esgrimida contra los estudios microbiológicos (el sesgo de composicionalidad) apoyándose en ANCOM-BC2 y métricas de Aitchison. La inclusión de rutinas de modelado mixto lineal explícito descarta el error crónico de tratar los perfiles temporales como cohortes transversales inconexas. Por consiguiente, los descubrimientos que surjan de la aplicación de este SOP respecto a la toxicidad secundaria de la terapia RIPE poseerán un grado de validez reproductible y exenta de artefactos metodológicos.

#bibliography("refs.bib", style: "ieee")
