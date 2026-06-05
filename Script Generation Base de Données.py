import os
import csv

# ==========================================
# INITIALISATION HFSS
# ==========================================
oDesktop.RestoreWindow()
oProject = oDesktop.GetActiveProject()
oDesign = oProject.GetActiveDesign()
oModule = oDesign.GetModule("ReportSetup")

# ==========================================
# PARAMETRES UTILISATEUR
# ==========================================

# Nom du setup en multi-frequencies
setup_name = "Setup1 : LastAdaptive"

# Nom du plan de mesures
radiation_surface = "Mesures"

# Plage de frequences de mesures
frequencies_hfss = ["0.1GHz", "0.2GHz", "0.5GHz", "0.8GHz", "1GHz", "2.42GHz"]

# Plage de hauteurs de mesure
heights = ["1mm", "3mm", "5mm"]

# Plage de champ mesure
fields = ["NearEX", "NearEY", "NearEZ", "NearHX", "NearHY", "NearHZ"]

# Conversion GHz en MHz
freq_to_mhz = {
    "0.1GHz": "100",
    "0.2GHz": "200",
    "0.5GHz": "500",
    "0.8GHz": "800",
    "1GHz": "1000",
    "2.42GHz" : "2420"
}

# ==========================================
# CREATION DU DOSSIER D'EXPORT "Export_CSV"
# ==========================================
project_path = oProject.GetPath()
# Nom du dossier d'export
export_dir = os.path.join(project_path, "Export_CSV")

if not os.path.exists(export_dir):
    os.makedirs(export_dir)

# Nom du fichier des valeurs électriques minimales et maximales
excel_file_path = os.path.join(export_dir, "Resultats_MinMax.csv")

total_iterations = len(frequencies_hfss) * len(heights) * len(fields)
current_count = 0

# ==========================================
# 1. CREATION DU RAPPORT UNIQUE INITIAL
# ==========================================
# Nom du rapport initial
report_name = "Visualisation_Dynamique"
current_trace = "dB(NearEX)"

oModule.CreateReport(report_name, "Near Fields", "Rectangular Contour Plot", setup_name, 
	["Context:=", radiation_surface], 
	[
		"_v:="			, ["All"],
		"_u:="			, ["All"],
        # Choix de la fréquence
		"Freq:="		, [frequencies_hfss[0]],
		"$Width:="		, ["Nominal"],
		"$Length:="		, ["Nominal"],
		"$H_substrat:="		, ["Nominal"],
		"$H_cuivre:="		, ["Nominal"],
		"$Radius:="		, ["Nominal"],
		"$L_piste:="		, ["Nominal"],
		"$L_port:="		, ["Nominal"],
		"$Lambda_4:="		, ["Nominal"],
        # Choix de la hauteur de mesure
		"$H_mesure:="		, [heights[0]]
	], 
	[
		"X Component:=", "_v",
		"Y Component:=", "_u",
		"Z Component:=", [current_trace]
	])

# ==========================================
# 2. BOUCLE D'ACTUALISATION ET D'EXPORT CSV
# ==========================================
with open(excel_file_path, mode='w') as csv_file:
    writer = csv.writer(csv_file, delimiter=';', lineterminator='\n')
    # Nom des colonnes du fichier de Min et Max
    writer.writerow(["Frequence (MHz)", "Hauteur (mm)", "Champ", "Minimum dB", "Maximum dB"])

    # Boucle de plages de frequences
    for freq in frequencies_hfss:
        # Boucle de plage de hauteurs
        for h in heights:
            # Boucle de plage de champs
            for field in fields:
                
                # Mise a jour du compteur console HFSS
                current_count += 1
                f_mhz_name = freq_to_mhz.get(freq, freq) + "MHz"
                f_mhz_print = freq_to_mhz.get(freq, freq)
                
                console_msg = "Extraction CSV : {} a {}MHz (H: {}) | Progression : {}/{}".format(
                    field, f_mhz_print, h, current_count, total_iterations
                )
                oDesktop.AddMessage(oProject.GetName(), oDesign.GetName(), 0, console_msg)
                
                new_trace = "dB({})".format(field)
                file_output_name = "{}_{}_{}".format(field, f_mhz_name, h)

                # ACTUALISATION RAPIDE DE LA TRACE
                try:
                    oModule.UpdateTraces(report_name, [current_trace], setup_name, 
                        ["Context:=", radiation_surface], 
                        [
                            "_v:="			, ["All"],
                            "_u:="			, ["All"],
                            "Freq:="		, [freq],
                            "$Width:="		, ["Nominal"],
                            "$Length:="		, ["Nominal"],
                            "$H_substrat:="		, ["Nominal"],
                            "$H_cuivre:="		, ["Nominal"],
                            "$Radius:="		, ["Nominal"],
                            "$L_piste:="		, ["Nominal"],
                            "$L_port:="		, ["Nominal"],
                            "$Lambda_4:="		, ["Nominal"],
                            "$H_mesure:="		, [h]
                        ], 
                        [
                            "X Component:="		, "_v",
                            "Y Component:="		, "_u",
                            "Z Component:="		, [new_trace]
                        ])
                    current_trace = new_trace
                except:
                    pass
                
                # EXPORTATION DE LA MATRICE DE DONNEES COMPLeTE (Pour MATLAB)
                csv_global_path = os.path.join(export_dir, file_output_name + ".csv")
                oModule.ExportToFile(report_name, csv_global_path, False)
                
                # EXTRACTION RAPIDE DES MIN/MAX DEPUIS LE FICHIER ENREGISTRe
                min_val = float('inf')
                max_val = float('-inf')
                
                if os.path.exists(csv_global_path):
                    with open(csv_global_path, 'r') as data_file:
                        lines = data_file.readlines()
                        for line in lines[1:]:
                            cols = line.split(',')
                            if len(cols) >= 3:
                                try:
                                    val = float(cols[2].strip())
                                    if val < min_val: min_val = val
                                    if val > max_val: max_val = val
                                except:
                                    pass
                
                if min_val == float('inf'):
                    min_val = "N/A"
                    max_val = "N/A"

                # INSCRIPTION DANS LE FICHIER GENERAL DE SYNTHESE
                f_mhz = freq_to_mhz.get(freq, freq)
                h_mm = h.replace("mm", "")
                writer.writerow([f_mhz, h_mm, field, min_val, max_val])

# ==========================================
# 3. NETTOYAGE APRES TOUTES LES BOUCLES
# ==========================================
oModule.DeleteReports([report_name])

oDesktop.AddMessage(oProject.GetName(), oDesign.GetName(), 0, "Script de base de donnees termine ! Tous les CSV de cartographie sont dans : " + export_dir)