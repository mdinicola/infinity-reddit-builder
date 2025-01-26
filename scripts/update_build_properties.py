import argparse

def update_api_utils(in_file: str, out_file: str, data: dict):
    contents = open(in_file, "r", encoding="utf-8-sig").read()
    # replace client_id
    contents = contents.replace(data['client_id']['old'], data['client_id']['new'])
    
    # replace user_agent
    user_agent_old = 'android:ml.docilealligator.infinityforreddit:" + BuildConfig.VERSION_NAME + " (by /u/Hostilenemy)'
    user_agent_new = f'android:personal-app:0.0.1 (by /u/{data['username']})'
    contents = contents.replace(user_agent_old, user_agent_new)

    # replace redirect url
    contents = contents.replace('infinity://localhost', 'http://127.0.0.1')

    # write out file
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(contents)


def update_build_gradle_file(in_file: str, out_file: str, data: dict):
    contents = open(in_file, "r", encoding="utf-8-sig").read()

    # add signing_configs section
    signing_configs = f"""
    signingConfigs {{
        release {{
            storeFile file("{data['keystore']['file_path']}")
            storePassword "{data['keystore']['password']}"
            keyAlias "infinity-for-reddit"
            keyPassword "{data['keystore']['password']}"
        }}
    }}
    buildTypes {{"""
    contents = contents.replace(r"""    buildTypes {""", signing_configs)

    # add signingConfig to buildTypes
    contents = contents.replace(
        r"""    buildTypes {
        release {""", 
        r"""    buildTypes {
        release {
            signingConfig signingConfigs.release""")

    # add baseline
    contents = contents.replace(
        "disable 'MissingTranslation'", 
        "disable 'MissingTranslation'\n        baseline = file(\"lint-baseline.xml\")"
    )

    # replace minSdk version
    contents = contents.replace("minSdk 21", f"minSdk {data['min_sdk_version']}")

    # write out file
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(contents)


def main(args: argparse.Namespace):
    build_gradle_file = f'{args.src_path}/Infinity-For-Reddit/app/build.gradle'
    build_gradle_file2 = f'{args.src_path}/Infinity-For-Reddit/app/build2.gradle'

    build_gradle_data = {
        'keystore': {
            'file_path': f'{args.src_path}/infinity-for-reddit.jks',
            'password': args.keystore_password
        },
        'min_sdk_version': args.min_sdk,
    }

    api_utils_file = f'{args.src_path}/Infinity-For-Reddit/app/src/main/java/ml/docilealligator/infinityforreddit/utils/APIUtils.java'
    api_utils_file2 = f'{args.src_path}/Infinity-For-Reddit/app/src/main/java/ml/docilealligator/infinityforreddit/utils/APIUtils2.java'

    api_utils_data = {
        'username': args.username,
        'client_id': {
            'old': 'NOe2iKrPPzwscA',
            'new': args.client_id
        }
    }

    reddit_username="mike"
    reddit_api_key="boop"

    update_api_utils(api_utils_file, api_utils_file2, api_utils_data)
    update_build_gradle_file(build_gradle_file, build_gradle_file2, build_gradle_data)


parser = argparse.ArgumentParser(
    prog='UpdateProperties',
    description='Updates properties of Infinity for Reddit build files'
)

parser.add_argument('--src-path')
parser.add_argument('--min-sdk', type=int)
parser.add_argument('--username', type=ascii)
parser.add_argument('--client-id', type=ascii)
parser.add_argument('--keystore-password')

main(parser.parse_args())