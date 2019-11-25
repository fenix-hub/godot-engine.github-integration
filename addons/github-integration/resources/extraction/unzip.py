import glob,zipfile,shutil,os,sys

archive = sys.argv[1]
destination = sys.argv[2]

with zipfile.ZipFile(archive) as zip:
    for zip_info in zip.infolist():
        if zip_info.filename == zip.infolist()[0].filename :
            continue
        zip_info.filename = zip_info.filename.replace(zip.infolist()[0].filename,'')
        zip.extract(zip_info, destination)
        
