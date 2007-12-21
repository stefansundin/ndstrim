@echo off

if not exist trimmed (
	mkdir trimmed
)

set size_original=0
set size_trimmed=0
set num_trimmed=0
set num_failed=0

for %%f in (*.nds) do (
	ndstrim "%%f" "trimmed/%%f"
	set /a num_trimmed+=1
	if exist trimmed/%%f (
		set /a size_original+=%%~zf
	) else (
		set /a num_failed+=1
	)
)

cd trimmed
for %%f in (*.nds) do (
	set /a size_trimmed+=%%~zf
)
cd ..

set /a size_original_mb=(size_original+500000)/1000000
set /a size_trimmed_mb=(size_trimmed+500000)/1000000
set /a size_saved=size_original-size_trimmed
set /a size_saved_mb=(size_saved+500000)/1000000

echo Trimmed %num_trimmed% roms (%num_failed% failed)
echo Original size: %size_original% bytes (%size_original_mb% MB)
echo Trimmed size: %size_trimmed% bytes (%size_trimmed_mb% MB)
echo Saved size: %size_saved% bytes (%size_saved_mb% MB)

pause
