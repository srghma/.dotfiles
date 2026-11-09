#!/usr/bin/env node

const fs = require('fs');
const YAML = require('yaml');

// Specify the path to your YAML file
const filePath = 'example.yaml';

try {
  // Read the YAML file
  const fileContents = fs.readFileSync(filePath, 'utf8');

  // Parse the YAML content into a Document (for preserving comments)
  const doc = YAML.parseDocument(fileContents);

  // Traverse the document to find the `name` field and replace it with `newname`
  const nameNode = doc.get('name');
  if (nameNode) {
    doc.set('newname', nameNode);
    doc.delete('name');
  }

  // Convert the document back to a string (with comments preserved)
  const newYaml = doc.toString();

  // Write the updated YAML back to the file or a new file
  fs.writeFileSync('updated_example.yaml', newYaml, 'utf8');

  console.log('YAML file updated successfully!');
} catch (e) {
  console.error('Error processing the YAML file:', e);
}
