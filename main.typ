
#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
)
#set text(
  font: "Linux Libertine",
  size: 11pt,
  lang: "es"
)

#set par(justify: true)
#show heading: set block(above: 1.4em, below: 1em)

#align(center)[
  #text(17pt, weight: "bold")[Guía Metodológica Estandarizada: Análisis de Disbiosis Intestinal en Tuberculosis (RIPE) mediante Secuenciación Nanopore]
  
  #v(0.5em)
  #text(12pt)[Proyecto: Evaluación del impacto de la terapia antituberculosa en la microbiota intestinal]
  #v(0.5em)
  #text(11pt)[Documento de Referencia Técnica - Febrero 2026]
]

#v(2em)

= 1. Introducción General

La presente guía establece el flujo de trabajo metodológico estandarizado para el análisis bioinformático del proyecto de investigación liderado por José Luis Villadiego, enfocado en evaluar las alteraciones estructurales de la microbiota intestinal en pacientes con tuberculosis pulmonar sometidos a terapia RIPE.

Este documento surge de la necesidad de adaptar las metodologías clásicas de secuenciación de amplicones cortos (Illumina 16S V3-V4) a la tecnología de *secuenciación de lectura larga Oxford Nanopore Technologies (ONT)*, la cual ha sido seleccionada como plataforma para este estudio (según recibo de servicio No. 51799476). La transición a Nanopore permite la secuenciación del gen 16S completo (~1500 pb), ofreciendo una resolución taxonómica superior (nivel de especie) frente a las regiones variables parciales, pero requiere herramientas bioinformáticas específicas para manejar sus perfiles de error característicos.

El alcance de este análisis se centra exclusivamente en la *estructura y composición de la comunidad microbiana* (diversidad alfa/beta, taxonomía diferencial y dinámica longitudinal), excluyendo inferencias funcionales predictivas o análisis inmunológicos mecanicistas, los cuales serán abordados en etapas posteriores del macroproyecto. Se prioriza el uso de software de código abierto y algoritmos robustos frente a la composicionalidad de los datos.

#pagebreak()

= 2. Flujo de Trabajo Metodológico

== Fase 0: Diseño Experimental y Coordinación de Secuenciación

Esta fase preliminar es crítica para garantizar que los datos crudos entregados por el servicio de secuenciación (Universidad del Valle) cumplan con los requisitos mínimos para el análisis bioinformático posterior.

=== Justificación
La tecnología Nanopore genera lecturas muy largas pero con una tasa de error por base superior a Illumina. Si la librería no se prepara o secuencia con los protocolos adecuados (ej. Kit 16S Barcoding SQK-16S024), la calidad de los datos puede comprometer la clasificación taxonómica. Es imperativo definir el formato de entrega para evitar incompatibilidades.

=== Fundamento Teórico
La secuenciación Nanopore se basa en medir cambios en la corriente eléctrica cuando una molécula de ADN atraviesa un poro proteico. La señal eléctrica ("squiggle") se decodifica a bases nucleotídicas mediante un proceso llamado *basecalling*. Los modelos de basecalling (ej. *Sup* o *Super-accurate*) utilizan redes neuronales profundas para minimizar errores.

=== Conceptos Clave
- *FASTQ*: Formato de archivo de texto que almacena secuencias biológicas y sus puntajes de calidad correspondientes.
- *Basecalling*: Proceso computacional de traducción de señales eléctricas crudas a secuencia de nucleótidos.
- *Barcode/Index*: Secuencia corta de ADN añadida a cada muestra para permitir la secuenciación multiplexada (varias muestras en una sola corrida).
- *Demultiplexing*: Separación informática de las lecturas de secuenciación en archivos individuales por muestra, basada en sus barcodes.

---

== Fase 1: Control de Calidad (QC) y Preprocesamiento

En esta etapa se filtran las lecturas de baja calidad y se eliminan secuencias no deseadas antes del análisis taxonómico.

=== Herramientas
- *NanoPlot / NanoStat*: Visualización de estadísticas de calidad.
- *NanoFilt / Chopper*: Filtrado por calidad y longitud.
- *Porechop*: Eliminación de adaptadores.

=== Justificación
A diferencia de los protocolos para Illumina (como DADA2), Nanopore requiere filtros adaptados a lecturas largas. Las lecturas muy cortas (< 1000 pb) en un protocolo de 16S completo suelen ser fragmentos degradados o inespecíficos. Las lecturas con baja calidad promedio (Phred < 10) introducen ruido en la asignación taxonómica.

=== Fundamento Teórico
El *Phred Quality Score* (Q) es una medida logarítmica de la probabilidad de error en una base llamada ($Q = -10 log_{10} P$). Un Q10 indica una precisión del 90% (1 error cada 10 bases), mientras que Q20 indica 99%. Para Nanopore 16S, un filtro de Q10 suele ser un balance aceptable entre retención de datos y precisión. El filtrado por longitud se basa en el tamaño biológico esperado del gen 16S (~1500 pb); desviaciones significativas sugieren amplificación inespecífica o degradación.

=== Conceptos Clave
- *Phred Score (Q)*: Medida estandarizada de la calidad de secuenciación.
- *Chimera*: Artefacto de PCR donde dos secuencias de ADN diferentes se unen artificialmente, creando un organismo híbrido inexistente.
- *Adaptador*: Secuencia de ADN sintético ligada a los extremos del fragmento de interés para facilitar la secuenciación.

---

== Fase 2: Clasificación Taxonómica Robusta (EMU)

Asignación de nombres científicos a las secuencias de ADN filtradas. Se sustituye el enfoque clásico de OTUs (QIIME 1) por métodos probabilísticos modernos.

=== Herramientas
- *EMU* (Expectation-Maximization for Ukranian/Ultralong reads): Clasificador taxonómico específico para 16S full-length de Nanopore.
- *Base de Datos*: SILVA 138 o rrnDB (optimizada para copias de 16S).

=== Justificación
Los clasificadores estándar (como Naive Bayes en QIIME2) suelen fallar con el perfil de error de Nanopore, clasificando erróneamente a nivel de género o especie. *EMU* utiliza un algoritmo de Expectativa-Maximización que es superior para manejar la incertidumbre de las lecturas largas con errores, permitiendo resolución a nivel de *especie* con mayor fiabilidad que el clustering de OTUs al 97%.

=== Fundamento Teórico
El algoritmo *EM (Expectation-Maximization)* iterativamente estima las abundancias relativas de las especies presentes.
1.  *Paso E (Expectation)*: Estima la probabilidad de que cada lectura provenga de una especie específica en la base de datos, considerando los errores de secuenciación.
2.  *Paso M (Maximization)*: Actualiza las abundancias estimadas de las especies basándose en las probabilidades calculadas.
Este ciclo se repite hasta converger, lo que permite "corregir" estadísticamente la asignación de lecturas ambiguas o con errores.

=== Conceptos Clave
- *ASV (Amplicon Sequence Variant)*: Secuencia exacta de ADN recuperada, usada como unidad fundamental de análisis en lugar de OTUs.
- *Resolución a nivel de especie*: Capacidad de distinguir entre organismos muy cercanos (ej. *E. coli* vs *Shigella*), facilitada por la longitud completa del gen 16S.
- *Mock Community*: Una mezcla de control con bacterias conocidas usada para validar la precisión del clasificador taxonómico.

---

== Fase 3: Análisis de Diversidad (Alpha y Beta)

Evaluación de la complejidad de las comunidades microbianas dentro de las muestras y las diferencias entre ellas.

=== Herramientas
- *QIIME 2* (plugins `diversity`, `deicode`).
- Métricas: Shannon, Faith's PD (Alpha); Aitchison, UniFrac Ponderado (Beta).

=== Justificación
Para comparar pacientes TB vs Controles, y pre- vs post-tratamiento, necesitamos métricas que resuman la estructura comunitaria. Se recomienda usar distancias basadas en *CLR (Centered Log-Ratio)* o UniFrac para evitar sesgos por profundidad de secuenciación desigual, en lugar de la rarefacción clásica que desecha datos válidos.

=== Fundamento Teórico
- *Diversidad Alpha*: Mide la "riqueza" (cuántas especies) y "equidad" (cómo se distribuyen) en una sola muestra. El índice de Shannon combina ambas propiedades (entropía de la información).
- *Diversidad Beta*: Mide la disimilitud entre dos muestras.
    - *UniFrac Ponderado*: Considera la distancia evolutiva entre bacterias y sus abundancias relativas. Si dos muestras comparten bacterias de ramas filogenéticas lejanas, son más distintas.
    - *Aitchison Distance*: Distancia euclidiana calculada sobre datos transformados por CLR. Es robusta a la composicionalidad (ver Fase 5).

=== Conceptos Clave
- *Rarefacción*: Técnica de submuestreo aleatorio para igualar el número de lecturas por muestra. Controvertida en estadística moderna por pérdida de datos.
- *PCoA (Principal Coordinates Analysis)*: Método de ordenación que visualiza las distancias complejas (multidimensionales) en un plano 2D o 3D.
- *Filogenia*: Historia evolutiva de las especies, representada en forma de árbol.

---

== Fase 4: Análisis Longitudinal

Evaluación de la dinámica temporal de la microbiota en los mismos sujetos a lo largo del tratamiento (T0, T2, T6, T9).

=== Herramientas
- *QIIME 2* (plugin `q2-longitudinal`).
- Métodos: *First differences*, *First distances*, *Linear Mixed Effects (LME)*.

=== Justificación
El diseño del proyecto Villadiego es longitudinal (medidas repetidas). Tratar los puntos temporales como muestras independientes (ANOVA simple) viola supuestos estadísticos y pierde potencia. `q2-longitudinal` modela explícitamente la correlación intra-sujeto, permitiendo distinguir cambios debidos al tratamiento de la variabilidad natural del individuo.

=== Fundamento Teórico
- *First Distances*: Calcula la distancia de diversidad beta entre un punto temporal y el siguiente *para el mismo sujeto*. Permite responder: "¿La microbiota cambia más drásticamente durante la fase intensiva (T0-T2) que en la fase de continuación (T2-T6)?".
- *Linear Mixed Effects (LME)*: Modelos de regresión que incluyen "efectos fijos" (tratamiento, tiempo) y "efectos aleatorios" (el paciente). Capturan la tendencia global ajustando por la línea base de cada individuo.

=== Conceptos Clave
- *Diseño de Medidas Repetidas*: Estudio donde se toman múltiples observaciones del mismo sujeto bajo diferentes condiciones o tiempos.
- *Volatilidad*: Magnitud del cambio en la composición microbiana a lo largo del tiempo.
- *Efecto Aleatorio*: Variable que captura la variabilidad idiosincrática de cada sujeto (ej. genética, dieta basal) no explicada por las variables experimentales.

---

== Fase 5: Análisis Diferencial y Composicionalidad

Identificación de las bacterias específicas (biomarcadores) que aumentan o disminuyen significativamente debido a la terapia RIPE.

=== Herramientas
- *ANCOM-BC2* (Analysis of Compositions of Microbiomes with Bias Correction).
- *Songbird* (opcional, para rankings log-ratio).
- *Exclusión*: No se utiliza *ComplexHeatmap* ni pruebas estándar (t-test, ANOVA) sobre abundancias crudas.

=== Justificación
Los datos de secuenciación son *composicionales*: solo conocemos la proporción de cada bacteria, no su cantidad absoluta. Si una bacteria dominante disminuye, las demás parecerán aumentar matemáticamente aunque su cantidad real no cambie. ANCOM-BC2 corrige este sesgo estimando un "bias de muestreo" para cada muestra. Se descarta ComplexHeatmap como herramienta analítica principal para evitar sobreinterpretar agrupamientos visuales sin sustento estadístico robusto.

=== Fundamento Teórico
- *Composicionalidad*: Propiedad de los datos que suman una constante (ej. 100%). Implica que las variables no son independientes; el cambio en una afecta a todas las demás.
- *Transformación CLR (Centered Log-Ratio)*: Transforma los datos del simplex (espacio de proporciones) al espacio real euclidiano mediante el logaritmo de la razón entre la abundancia de una característica y la media geométrica de todas las características. $`"CLR"`(x) = \ln(x / g(x))$.
- *Bias Correction*: Ajuste matemático que intenta recuperar las abundancias absolutas (o sus diferencias reales) a partir de las relativas observadas.

=== Conceptos Clave
- *FDR (False Discovery Rate)*: Corrección estadística para múltiples comparaciones (ej. Benjamini-Hochberg) necesaria cuando se prueban cientos de bacterias simultáneamente.
- *Simplex*: Espacio matemático donde residen los datos composicionales (como un triángulo para 3 componentes que suman 1).
- *Log-Fold Change*: Medida de cuánto cambia una cantidad (en escala logarítmica) entre dos condiciones.

#pagebreak()

= 3. Conclusión

Esta guía metodológica reorienta el análisis del proyecto TB-RIPE hacia estándares contemporáneos (2025-2026), priorizando la *robustez estadística* frente a la mera descripción visual. Al adoptar la secuenciación Nanopore de longitud completa y herramientas conscientes de la composicionalidad (ANCOM-BC2, métricas robustas), el estudio podrá reportar hallazgos taxonómicos a nivel de especie con alta fiabilidad.

La eliminación de visualizaciones complejas no esenciales (como *ComplexHeatmap*) y la adopción de modelos longitudinales formales (`q2-longitudinal`) aseguran que las conclusiones sobre la disbiosis sean artefactos biológicos reales y no consecuencias del ruido técnico o sesgos de análisis. Este flujo de trabajo garantiza que, aunque el tamaño muestral sea limitado (n=20 subcohorte), la potencia analítica sea máxima.
