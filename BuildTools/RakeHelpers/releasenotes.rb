module ReleaseNotes
  def self.generate(build_label, release_notes_path, base_ref)
    system(
      'scriptcs ' \
      "#{BUILD_TOOLS_DIR}\\ReleaseNotesGenerator\\bootstrap.csx -- " \
      "\"#{build_label}\" "\
      "\"#{release_notes_path}\" "\
      "\"#{base_ref}\""
    ) || raise("scriptcs ReleaseNotesGenerator #{build_label} failed")
  end
end
