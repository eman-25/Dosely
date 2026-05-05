// lib/data/health_data.dart
// Comprehensive lists for allergies, conditions, and medications

class HealthData {
  // ─────────────────────────────────────────────
  // ALLERGIES — comprehensive list
  // ─────────────────────────────────────────────
  static const List<String> allergies = [
    'None',
    // Food
    'Peanuts',
    'Tree Nuts (Almonds, Cashews, Walnuts)',
    'Milk / Dairy',
    'Eggs',
    'Wheat / Gluten',
    'Soy',
    'Shellfish (Shrimp, Crab, Lobster)',
    'Fish (Tuna, Salmon, Cod)',
    'Sesame',
    'Mustard',
    'Celery',
    'Lupin',
    'Molluscs (Squid, Oysters)',
    'Sulphites / Sulphur Dioxide',
    // Drug / Medication
    'Penicillin',
    'Amoxicillin',
    'Cephalosporins',
    'Sulfonamides (Sulfa drugs)',
    'Aspirin / NSAIDs',
    'Ibuprofen',
    'Codeine / Opioids',
    'Tetracycline',
    'Erythromycin',
    'Fluoroquinolones (Ciprofloxacin)',
    'Insulin (Animal-derived)',
    'Contrast Dye (Iodine)',
    'Local Anesthetics (Lidocaine)',
    // Environmental
    'Dust Mites',
    'Pollen (Grass)',
    'Pollen (Tree)',
    'Pollen (Weed)',
    'Pet Dander (Cats)',
    'Pet Dander (Dogs)',
    'Mold / Fungal Spores',
    'Cockroach Allergens',
    // Skin / Contact
    'Latex',
    'Nickel',
    'Fragrance / Perfume',
    'Formaldehyde',
    'Preservatives (Parabens)',
    'Hair Dye (PPD)',
    'Sunscreen Ingredients',
    'Adhesive / Bandage Glue',
    // Insect
    'Bee / Wasp Sting',
    'Fire Ant Sting',
    // Other
    'Alcohol',
    'Gelatin',
    'Vaccines (Egg-based)',
  ];

  // ─────────────────────────────────────────────
  // CHRONIC CONDITIONS — comprehensive list
  // ─────────────────────────────────────────────
  static const List<String> chronicConditions = [
    'None',
    // Cardiovascular
    'Hypertension (High Blood Pressure)',
    'Heart Disease / Coronary Artery Disease',
    'Heart Failure',
    'Atrial Fibrillation',
    'High Cholesterol / Hyperlipidemia',
    'Peripheral Artery Disease',
    'Deep Vein Thrombosis (DVT)',
    // Metabolic / Endocrine
    'Type 1 Diabetes',
    'Type 2 Diabetes',
    'Pre-Diabetes',
    'Thyroid Disease (Hypothyroidism)',
    'Thyroid Disease (Hyperthyroidism)',
    'Obesity',
    'Metabolic Syndrome',
    'Cushing Syndrome',
    'Addison Disease',
    // Respiratory
    'Asthma',
    'Chronic Obstructive Pulmonary Disease (COPD)',
    'Chronic Bronchitis',
    'Emphysema',
    'Sleep Apnea',
    'Pulmonary Hypertension',
    'Interstitial Lung Disease',
    'Cystic Fibrosis',
    // Digestive / GI
    'Gastroesophageal Reflux Disease (GERD)',
    'Peptic Ulcer Disease',
    'Irritable Bowel Syndrome (IBS)',
    'Crohn Disease',
    'Ulcerative Colitis',
    'Celiac Disease',
    'Chronic Liver Disease',
    'Cirrhosis',
    'Chronic Pancreatitis',
    'Gallbladder Disease',
    // Kidney / Urinary
    'Chronic Kidney Disease (CKD)',
    'Kidney Stones',
    'Urinary Incontinence',
    'Polycystic Kidney Disease',
    // Neurological
    'Epilepsy / Seizure Disorder',
    'Migraine',
    'Parkinson Disease',
    'Multiple Sclerosis',
    'Alzheimer Disease / Dementia',
    'Stroke (History)',
    'Peripheral Neuropathy',
    // Mental Health
    'Depression',
    'Anxiety Disorder',
    'Bipolar Disorder',
    'Schizophrenia',
    'ADHD',
    'PTSD',
    'Obsessive Compulsive Disorder (OCD)',
    // Musculoskeletal
    'Osteoarthritis',
    'Rheumatoid Arthritis',
    'Osteoporosis',
    'Fibromyalgia',
    'Gout',
    'Lupus (SLE)',
    'Ankylosing Spondylitis',
    // Blood / Immune
    'Anemia (Iron Deficiency)',
    'Sickle Cell Disease',
    'Hemophilia',
    'HIV / AIDS',
    'Autoimmune Hepatitis',
    'Psoriasis',
    'Eczema / Atopic Dermatitis',
    // Cancer (History)
    'Cancer — Breast',
    'Cancer — Prostate',
    'Cancer — Colon',
    'Cancer — Lung',
    'Cancer — Skin (Melanoma)',
    'Cancer — Other',
    // Eye / Ear
    'Glaucoma',
    'Macular Degeneration',
    'Cataracts',
    'Chronic Ear Infections',
    // Other
    'Chronic Pain Syndrome',
    'Chronic Fatigue Syndrome',
  ];
// ─────────────────────────────────────────────
  // MEDICATIONS — comprehensive list (120 medicines)
  // ─────────────────────────────────────────────
  static const List<String> medications = [
    'None',

    // ── Pain & Anti-inflammatory ──────────────────
    'Advil 200mg',              // Ibuprofen
    'Advil 400mg',              // Ibuprofen
    'Advil 600mg',              // Ibuprofen
    'Advil 800mg',              // Ibuprofen
    'Brufen 200mg',             // Ibuprofen
    'Brufen 400mg',             // Ibuprofen
    'Brufen 600mg',             // Ibuprofen
    'Brufen 800mg',             // Ibuprofen
    'Diclofenac 25mg',          // Diclofenac
    'Diclofenac 50mg',          // Diclofenac
    'Diclofenac 75mg',          // Diclofenac
    'Diclofenac 100mg',         // Diclofenac
    'Voltaren 25mg',            // Diclofenac
    'Voltaren 50mg',            // Diclofenac
    'Voltaren 75mg',            // Diclofenac
    'Voltaren 100mg',           // Diclofenac
    'Voltaren Gel 1%',          // Diclofenac Topical
    'Cataflam 25mg',            // Diclofenac Potassium
    'Cataflam 50mg',            // Diclofenac Potassium
    'Cataflam 75mg',            // Diclofenac Potassium
    'Cataflam 100mg',           // Diclofenac Potassium

    // ── Paracetamol ───────────────────────────────
    'Panadol 500mg',            // Paracetamol
    'Panadol Extra 500mg',      // Paracetamol + Caffeine
    'Panadol Cold&Flu 500mg',   // Paracetamol + Decongestant
    'Panadol Night 500mg',      // Paracetamol + Antihistamine
    'Panadol Advance 500mg',    // Paracetamol
    'Panadol Syrup 120mg/5ml',  // Paracetamol

    // ── Cold & Flu ────────────────────────────────
    'Fludrex Standard dose',    // Paracetamol + Pseudoephedrine + Dextromethorphan + Antihistamine

    // ── Antibiotics ───────────────────────────────
    'Amoxicillin 250mg',        // Amoxicillin
    'Amoxicillin 500mg',        // Amoxicillin
    'Augmentin 625mg',          // Amoxicillin + Clavulanic Acid
    'Augmentin 1g',             // Amoxicillin + Clavulanic Acid
    'Flagyl 500mg',             // Metronidazole
    'Zithromax 500mg',          // Azithromycin
    'Cipro 250mg',              // Ciprofloxacin
    'Cipro 500mg',              // Ciprofloxacin
    'Doxycycline 100mg',        // Doxycycline
    'Ceporex 250mg',            // Cephalexin
    'Ceporex 500mg',            // Cephalexin

    // ── Antihistamines ────────────────────────────
    'Zyrtec 10mg',              // Cetirizine
    'Claritin 10mg',            // Loratadine
    'Aerius 5mg',               // Desloratadine
    'Telfast 120mg',            // Fexofenadine

    // ── Respiratory & Asthma ─────────────────────
    'Ventolin Inhaler 100mcg',  // Salbutamol
    'Seretide Inhaler 250mcg',  // Fluticasone + Salmeterol
    'Symbicort Inhaler 160mcg', // Budesonide + Formoterol
    'Nasonex Spray 50mcg',      // Mometasone
    'Singulair 10mg',           // Montelukast
    'Singulair 5mg',            // Montelukast
    'Prednisolone 5mg',         // Prednisolone
    'Prednisolone 10mg',        // Prednisolone
    'Prednisolone 20mg',        // Prednisolone

    // ── Gastrointestinal ─────────────────────────
    'Nexium 40mg',              // Esomeprazole
    'Losec 20mg',               // Omeprazole
    'Gaviscon Standard dose',   // Alginate
    'Rennie Standard dose',     // Calcium Carbonate
    'Imodium 2mg',              // Loperamide
    'Buscopan 10mg',            // Hyoscine Butylbromide
    'Spasfon 80mg',             // Phloroglucinol
    'Duspatalin 135mg',         // Mebeverine

    // ── Diabetes ─────────────────────────────────
    'Glucophage 500mg',         // Metformin
    'Glucophage XR 500mg',      // Metformin Extended Release
    'Glucophage XR 1000mg',     // Metformin Extended Release
    'Januvia 100mg',            // Sitagliptin
    'Diamicron 30mg',           // Gliclazide
    'Diamicron 60mg',           // Gliclazide
    'Amaryl 1mg',               // Glimepiride
    'Amaryl 2mg',               // Glimepiride
    'Amaryl 4mg',               // Glimepiride
    'Insulin Lantus Injection',  // Insulin Glargine
    'NovoRapid Injection',      // Insulin Aspart
    'Humalog Injection',        // Insulin Lispro
    'NovoMix 30 Injection',     // Insulin Aspart Mix
    'Mixtard 30 Injection',     // Insulin Human 30/70

    // ── Blood Pressure & Heart ────────────────────
    'Concor 2.5mg',             // Bisoprolol
    'Concor 5mg',               // Bisoprolol
    'Concor 10mg',              // Bisoprolol
    'Norvasc 5mg',              // Amlodipine
    'Norvasc 10mg',             // Amlodipine
    'Coversyl 5mg',             // Perindopril
    'Coversyl 10mg',            // Perindopril
    'Cozaar 50mg',              // Losartan
    'Cozaar 100mg',             // Losartan
    'Lasix 40mg',               // Furosemide
    'Lasix 80mg',               // Furosemide
    'Aspirin 100mg',            // Acetylsalicylic Acid
    'Brilinta 90mg',            // Ticagrelor
    'Plavix 75mg',              // Clopidogrel

    // ── Cholesterol ───────────────────────────────
    'Lipitor 20mg',             // Atorvastatin

    // ── Thyroid ───────────────────────────────────
    'Eltroxin 50mcg',           // Levothyroxine
    'Eltroxin 100mcg',          // Levothyroxine
    'Euthyrox 25mcg',           // Levothyroxine
    'Euthyrox 50mcg',           // Levothyroxine
    'Euthyrox 100mcg',          // Levothyroxine
    'Carbimazole 5mg',          // Carbimazole
    'Carbimazole 10mg',         // Carbimazole

    // ── Mental Health ─────────────────────────────
    'Xanax 0.25mg',             // Alprazolam
    'Xanax 0.5mg',              // Alprazolam
    'Xanax 1mg',                // Alprazolam
    'Cipralex 10mg',            // Escitalopram
    'Cipralex 20mg',            // Escitalopram
    'Zoloft 50mg',              // Sertraline
    'Zoloft 100mg',             // Sertraline

    // ── Pregnancy & Supplements ───────────────────
    'Folic Acid 400mcg',        // Folic Acid
    'Folic Acid 5mg',           // Folic Acid
    'Pregnacare Standard dose', // Folic Acid + Iron + Multivitamins
    'Obimin Standard dose',     // Folic Acid + Iron + Multivitamins
    'Calcimate 500mg',          // Calcium Carbonate
    'Caltrate 600mg',           // Calcium Carbonate + Vitamin D
    'Utrogestan 200mg',         // Progesterone
    'Cyclogest 400mg',          // Progesterone
    'Ondansetron 4mg',          // Ondansetron
    'Ondansetron 8mg',          // Ondansetron
    'Tardyferon 80mg',          // Iron (Ferrous Sulfate)
    'Tardyferon 160mg',         // Iron (Ferrous Sulfate)

    // ── Vitamins & Supplements ────────────────────
    'Neurobion Standard dose',              // Vitamin B Complex
    'Centrum Multivitamin Standard dose',   // Multivitamins

    // ── Topical ───────────────────────────────────
    'Voltaren Gel 1%',          // Diclofenac Topical
    'Fucidin Cream 2%',         // Fusidic Acid
    'Bepanthen Cream 5%',       // Dexpanthenol
    'Canesten Cream 1%',        // Clotrimazole
  ];

  // ─────────────────────────────────────────────
  // SPECIAL CONDITIONS
  // ─────────────────────────────────────────────
  static const List<String> specialConditions = [
    'None',
    'Pregnant',
    'Breastfeeding / Lactating',
    'Trying to Conceive',
    'Post-Surgery (Recent)',
    'Elderly (65+)',
    'Child / Pediatric',
    'Immunocompromised',
    'On Dialysis',
    'Organ Transplant Recipient',
    'Undergoing Chemotherapy',
  ];
}