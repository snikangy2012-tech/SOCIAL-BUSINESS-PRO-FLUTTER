/**
 * Script pour appliquer automatiquement SystemUIScaffold partout dans l'application
 *
 * RÉSOUT DEUX PROBLÈMES sur TOUS les écrans :
 * 1. Barre système blanche opaque avec icônes noires
 * 2. Empêche le contenu de se cacher sous la barre système
 *
 * UTILISATION :
 * node apply_system_ui_fix.js
 */

const fs = require("fs");
const path = require("path");

// Fichiers à exclure (déjà corrigés manuellement)
const EXCLUDED_FILES = [
  "main_scaffold.dart",
  "vendeur_main_screen.dart",
  "admin_main_screen.dart",
  "livreur_main_screen.dart",
  "system_ui_scaffold.dart", // Le widget lui-même
];

// Fichiers à traiter (tous les fichiers dans lib/screens/)
const SCREENS_DIR = path.join(__dirname, "lib", "screens");

let modifiedFiles = 0;
let skippedFiles = 0;
let errors = [];

/**
 * Vérifie si un fichier doit être traité
 */
function shouldProcessFile(filePath) {
  const fileName = path.basename(filePath);

  // Exclure les fichiers dans la liste d'exclusion
  if (EXCLUDED_FILES.includes(fileName)) {
    return false;
  }

  // Ne traiter que les fichiers .dart
  if (!filePath.endsWith(".dart")) {
    return false;
  }

  return true;
}

/**
 * Vérifie si un fichier utilise déjà SystemUIScaffold
 */
function alreadyUsesSystemUIScaffold(content) {
  return (
    content.includes("SystemUIScaffold") ||
    content.includes("SystemUIPopScaffold")
  );
}

/**
 * Vérifie si un fichier a des Scaffold à remplacer
 */
function hasScaffoldToReplace(content) {
  // Cherche "return Scaffold(" ou "return const Scaffold("
  return /return\s+(const\s+)?Scaffold\(/g.test(content);
}

/**
 * Ajoute l'import de SystemUIScaffold si nécessaire
 */
function addImportIfNeeded(content) {
  const importStatement = "import '../../widgets/system_ui_scaffold.dart';";

  // Si l'import existe déjà, ne rien faire
  if (content.includes(importStatement)) {
    return content;
  }

  // Trouver la dernière ligne d'import
  const lines = content.split("\n");
  let lastImportIndex = -1;

  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim().startsWith("import ")) {
      lastImportIndex = i;
    }
  }

  // Ajouter l'import après le dernier import existant
  if (lastImportIndex !== -1) {
    lines.splice(lastImportIndex + 1, 0, importStatement);
    return lines.join("\n");
  }

  // Si aucun import trouvé, ajouter au début du fichier
  return importStatement + "\n" + content;
}

/**
 * Remplace tous les Scaffold par SystemUIScaffold dans le contenu
 */
function replaceScaffolds(content) {
  let modified = content;

  // Remplacer "return Scaffold(" par "return SystemUIScaffold("
  modified = modified.replace(
    /return\s+Scaffold\(/g,
    "return SystemUIScaffold("
  );

  // Remplacer "return const Scaffold(" par "return SystemUIScaffold("
  // (on retire const car SystemUIScaffold n'est pas const)
  modified = modified.replace(
    /return\s+const\s+Scaffold\(/g,
    "return SystemUIScaffold("
  );

  // Remplacer les occurrences de "child: Scaffold(" par "child: SystemUIScaffold("
  modified = modified.replace(
    /child:\s+Scaffold\(/g,
    "child: SystemUIScaffold("
  );
  modified = modified.replace(
    /child:\s+const\s+Scaffold\(/g,
    "child: SystemUIScaffold("
  );

  return modified;
}

/**
 * Traite un fichier
 */
function processFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, "utf8");

    // Vérifier si déjà corrigé
    if (alreadyUsesSystemUIScaffold(content)) {
      console.log(`⏭️  Ignoré (déjà corrigé): ${path.basename(filePath)}`);
      skippedFiles++;
      return;
    }

    // Vérifier si contient des Scaffold
    if (!hasScaffoldToReplace(content)) {
      console.log(`⏭️  Ignoré (pas de Scaffold): ${path.basename(filePath)}`);
      skippedFiles++;
      return;
    }

    // Ajouter l'import
    let modified = addImportIfNeeded(content);

    // Remplacer les Scaffold
    modified = replaceScaffolds(modified);

    // Vérifier si des modifications ont été faites
    if (modified === content) {
      console.log(
        `⏭️  Ignoré (aucune modification): ${path.basename(filePath)}`
      );
      skippedFiles++;
      return;
    }

    // Sauvegarder le fichier modifié
    fs.writeFileSync(filePath, modified, "utf8");
    console.log(`✅ Modifié: ${path.basename(filePath)}`);
    modifiedFiles++;
  } catch (error) {
    console.error(
      `❌ Erreur pour ${path.basename(filePath)}: ${error.message}`
    );
    errors.push({ file: filePath, error: error.message });
  }
}

/**
 * Parcourt récursivement un dossier et traite tous les fichiers .dart
 */
function processDirectory(directory) {
  const items = fs.readdirSync(directory);

  for (const item of items) {
    const fullPath = path.join(directory, item);
    const stat = fs.statSync(fullPath);

    if (stat.isDirectory()) {
      // Récursion sur les sous-dossiers
      processDirectory(fullPath);
    } else if (stat.isFile() && shouldProcessFile(fullPath)) {
      processFile(fullPath);
    }
  }
}

/**
 * Main
 */
console.log("🚀 Début de l'application de SystemUIScaffold...\n");
console.log(`📂 Dossier: ${SCREENS_DIR}\n`);
console.log("📝 Fichiers exclus:", EXCLUDED_FILES.join(", "));
console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

// Vérifier que le dossier existe
if (!fs.existsSync(SCREENS_DIR)) {
  console.error(`❌ Le dossier ${SCREENS_DIR} n'existe pas !`);
  process.exit(1);
}

// Traiter tous les fichiers
processDirectory(SCREENS_DIR);

// Rapport final
console.log("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
console.log("📊 RAPPORT FINAL\n");
console.log(`✅ Fichiers modifiés: ${modifiedFiles}`);
console.log(`⏭️  Fichiers ignorés: ${skippedFiles}`);
console.log(`❌ Erreurs: ${errors.length}`);

if (errors.length > 0) {
  console.log("\n❌ ERREURS DÉTAILLÉES:");
  errors.forEach(({ file, error }) => {
    console.log(`  - ${path.basename(file)}: ${error}`);
  });
}

console.log("\n✅ Script terminé !");

// Retourner un code d'erreur si des erreurs se sont produites
process.exit(errors.length > 0 ? 1 : 0);
