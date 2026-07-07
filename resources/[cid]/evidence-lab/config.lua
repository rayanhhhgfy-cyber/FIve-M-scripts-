Config = Config or {}

Config.EvidenceLab = {
    LabZones = {
        MRPD = { coords = vector3(444.0, -980.0, 30.0), radius = 3.0 },
        CIDHQ = { coords = vector3(108.0, -740.0, 45.0), radius = 5.0 },
        Davis = { coords = vector3(365.0, -1604.0, 25.0), radius = 3.0 }
    },

    AnalysisTypes = {
        DNA = { time = 10000, label = 'DNA Analysis', item = 'dna_sample' },
        Fingerprint = { time = 8000, label = 'Fingerprint Analysis', item = 'fingerprint_card' },
        Digital = { time = 12000, label = 'Digital Forensics', item = 'usb_drive' },
        Chemical = { time = 9000, label = 'Chemical Analysis', item = 'chemical_sample' },
        Ballistic = { time = 7000, label = 'Ballistic Matching', item = 'bullet_casing' },
        Document = { time = 6000, label = 'Document Examination', item = 'document_evidence' }
    },

    Equipment = {
        { item = 'microscope', label = 'Microscope', price = 0, rank = 0 },
        { item = 'spectrometer', label = 'Spectrometer', price = 0, rank = 1 },
        { item = 'fingerprint_kit', label = 'Fingerprint Kit', price = 0, rank = 0 },
        { item = 'chemical_kit', label = 'Chemical Test Kit', price = 0, rank = 1 },
        { item = 'digital_kit', label = 'Digital Recovery Kit', price = 0, rank = 2 }
    },

    ResultCategories = {
        Positive = { label = 'Match Found', color = 'success' },
        Negative = { label = 'No Match', color = 'error' },
        Inconclusive = { label = 'Inconclusive', color = 'warning' },
        Contaminated = { label = 'Sample Contaminated', color = 'error' }
    },

    TargetOptions = {
        analysis = { icon = 'fas fa-microscope', label = 'Analyze Evidence', group = 'cid', distance = 1.5 },
        equipment = { icon = 'fas fa-tools', label = 'Lab Equipment', group = 'cid', distance = 2.0 }
    },

    Restrictions = { requireDuty = true, allowedJobs = { 'cid', 'police' }, minRank = 0 }
}
