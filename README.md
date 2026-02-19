# Build Instructions for APK

To build the APK for this project, follow the steps below:

1. **Clone the Repository**  
   Run the following command to clone the repository:
   ```bash
   git clone https://github.com/ringuemkt-rgb/cria-do-tatame.git
   cd cria-do-tatame
   ```

2. **Install Dependencies**  
   Use Gradle to install all necessary dependencies:
   ```bash
   ./gradlew build
   ```

3. **Build the APK**  
   Now you can build the APK by running:
   ```bash
   ./gradlew assembleDebug
   ```
   The APK will be located in the `app/build/outputs/apk/debug/` directory.

---

# Using GitHub Actions

This repository integrates GitHub Actions to automate workflows. Here's how to use it:

1. **Continuous Integration**: Whenever a push is made to the main branch, GitHub Actions will automatically trigger the CI workflow to run tests and build the project.

2. **Configuration**: You can find the configuration files under the `.github/workflows/` directory. Modify these YAML files to customize the workflow as per your requirements.